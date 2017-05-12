package DataStore::CAS::Simple;
use 5.008;
use Moo 1.000007;
use Carp;
use Try::Tiny;
use Digest 1.16 ();
use File::Spec 3.33;
use File::Spec::Functions 'catfile', 'catdir', 'canonpath';
use File::Temp 0.22 ();

our $VERSION = '0.020001';

# ABSTRACT: Simple file/directory based CAS implementation


has path             => ( is => 'ro', required => 1 );
has copy_buffer_size => ( is => 'rw', default => sub { 256*1024 } );
has _config          => ( is => 'rwp', init_arg => undef );
sub fanout              { [ $_[0]->fanout_list ] }
sub fanout_list         { @{ $_[0]->_config->{fanout} } }
sub digest              { $_[0]->_config->{digest} }

has _fanout_regex    => ( is => 'lazy' );

sub _build__fanout_regex {
	my $self= shift;
	my $regex= join('', map { "(.{$_})" } $self->fanout_list ).'(.*)';
	qr/$regex/;
}

with 'DataStore::CAS';


sub BUILD {
	my ($self, $args)= @_;
	my ($create, $ignore_version, $digest, $fanout, $_notest)=
		delete @{$args}{'create','ignore_version','digest','fanout','_notest'};

	# Check for invalid params
	my @inval= grep { !$self->can($_) } keys %$args;
	croak "Invalid parameter: ".join(', ', @inval)
		if @inval;

	# Path is required, and must be a directory
	my $path= $self->path;
	if (!-d $path) {
		croak "Path '$path' is not a directory"
			unless $create;
		mkdir $path
			or die "Can't create directory '$path'";
	}	

	# Check directory
	my $setup= 0;
	unless (-f catfile($path, 'conf', 'VERSION')) {
		croak "Path does not appear to be a valid CAS : '$path'"
			unless $create;

		# Here, we are creating a new CAS directory
		$self->create_store({ digest => $digest, path => $path, fanout => $fanout });
		$setup= 1;
	}

	$self->_set__config( $self->_load_config($path, { ignore_version => $ignore_version }) );

	if ($setup) {
		$self->put('');
	} else {
		# Properly initialized CAS will always contain an entry for the empty string
		croak "CAS dir '$path' is missing a required file"
		     ." (has it been initialized?)"
			unless $self->validate($self->hash_of_null);
	}

	return $self;
}


sub create_store {
	my $class= shift;
	$class= ref $class if ref $class;
	my %params= (@_ == 1? %{$_[0]} : @_);
	
	defined $params{path} or croak "Missing required param 'path'";
	-d $params{path} or croak "Directory '$params{path}' does not exist";
	# Make sure we are creating in an empty dir
	croak "Directory '$params{path}' is not empty\n"
		unless $class->_is_dir_empty($params{path});

	$params{digest} ||= 'SHA-1';
	# Make sure the algorithm is available
	my $found= ( try { defined $class->_new_digest($params{digest}); } catch { print "#$_\n"; 0; } )
		or croak "Digest algorithm '".$params{digest}."'"
		        ." is not available on this system.\n";

	$params{fanout} ||= [ 1, 2 ];
	# make sure the fanout isn't insane
	$params{fanout}= $class->_parse_fanout(join(' ',@{$params{fanout}}));

	my $conf_dir= catdir($params{path}, 'conf');
	mkdir($conf_dir) or croak "mkdir($conf_dir): $!";
	$class->_write_config_setting($params{path}, 'VERSION', $class.' '.$VERSION."\n");
	$class->_write_config_setting($params{path}, 'digest', $params{digest}."\n");
	$class->_write_config_setting($params{path}, 'fanout', join(' ', @{$params{fanout}})."\n");
}

# This method loads the digest and fanout configuration and validates it
# It is called during the constructor.
sub _load_config {
	my ($class, $path, $flags)= @_;
	$class= ref $class if ref $class;
	my %params;
	
	# Version str is "$PACKAGE $VERSION\n", where version is a number but might have a
	#   string suffix on it
	$params{storage_format_version}=
		$class->_parse_version($class->_read_config_setting($path, 'VERSION'));
	unless ($flags->{ignore_version}) {
		while (my ($pkg, $ver)= each %{$params{storage_format_version}}) {
			my $cur_ver= try { $pkg->VERSION };
			defined $cur_ver
				or croak "Class mismatch: storage dir was created using $pkg"
					." but that package is not loaded now\n";
			(try { $pkg->VERSION($ver); 1; } catch { 0 })
				or croak "Version mismatch: storage dir was created using"
					." version '$ver' of $pkg but this is only $cur_ver\n";
		}
	}

	# Get the digest algorithm name
	$params{digest}=
		$class->_parse_digest($class->_read_config_setting($path, 'digest'));
	# Check for digest algorithm availability
	my $found= ( try { $class->_new_digest($params{digest}); 1; } catch { 0; } )
		or croak "Digest algorithm '".$params{digest}."'"
		        ." is not available on this system.\n";

	# Get the directory fan-out specification
	$params{fanout}=
		$class->_parse_fanout($class->_read_config_setting($path, 'fanout'));

	return \%params;
}

sub _is_dir_empty {
	my (undef, $path)= @_;
	opendir(my $dh, $path)
		or die "opendir($path): $!";
	my @entries= grep { $_ ne '.' and $_ ne '..' } readdir($dh);
	closedir($dh);
	return @entries == 0;
}

# In the name of being "Simple", I decided to just read and write
# raw files for each parameter instead of using JSON or YAML.
# It is not expected that this module will have very many options.
# Subclasses will likely use YAML.

sub _write_config_setting {
	my (undef, $path, $name, $content)= @_;
	$path= catfile($path, 'conf', $name);
	open(my $f, '>', $path)
		or croak "Failed to open '$path' for writing: $!\n";
	(print $f $content) && (close $f)
		or croak "Failed while writing '$path': $!\n";
}
sub _read_config_setting {
	my (undef, $path, $name)= @_;
	$path= catfile($path, 'conf', $name);
	open(my $f, '<', $path)
		or croak "Failed to read '$path' : $!\n";
	local $/= undef;
	my $str= <$f>;
	defined $str and length $str or croak "Failed to read '$path' : $!\n";
	return $str;
}

sub _parse_fanout {
	my (undef, $fanout)= @_;
	chomp($fanout);
	my @fanout;
	# Sanity check on the fanout
	my $total_digits= 0;
	for (split /\s+/, $fanout) {
		($_ =~ /^(\d+)$/) or croak "Invalid fanout spec";
		push @fanout, $1;
		$total_digits+= $1;
		croak "Too large fanout in one directory ($1)" if $1 > 3;
	}
	croak "Too many digits of fanout! ($total_digits)" if $total_digits > 5;
	return \@fanout;
}

sub _parse_digest {
	my (undef, $digest)= @_;
	chomp($digest);
	($digest =~ /^(\S+)$/)
		or croak "Invalid digest algorithm name: '$digest'\n";
	return $1;
}

sub _parse_version {
	my (undef, $version)= @_;
	my %versions;
	for my $line (split /\r?\n/, $version) {
		($line =~ /^([A-Za-z0-9:_]+) ([0-9.]+)/)
			or croak "Invalid version string: '$line'\n";
		$versions{$1}= $2;
	}
	return \%versions;
}


sub get {
	my ($self, $hash)= @_;
	my $fname= catfile($self->_path_for_hash($hash));
	return undef
		unless (my ($size, $blksize)= (stat $fname)[7,11]);
	return bless {
		# required
		store      => $self,
		hash       => $hash,
		size       => $size,
		# extra info
		block_size => $blksize,
		local_file => $fname,
	}, 'DataStore::CAS::Simple::File';
}


sub new_write_handle {
	my ($self, $flags)= @_;
	$flags ||= {};
	my $data= {
		wrote   => 0,
		dry_run => $flags->{dry_run},
		hash    => $flags->{known_digests}{$self->digest},
		stats   => $flags->{stats},
	};
	
	$data->{dest_file}= File::Temp->new( TEMPLATE => 'temp-XXXXXXXX', DIR => $self->path )
		unless $data->{dry_run};
	
	$data->{digest}= $self->_new_digest
		unless defined $data->{known_hash};
	
	return DataStore::CAS::FileCreatorHandle->new($self, $data);
}

sub _handle_write {
	my ($self, $handle, $buffer, $count, $offset)= @_;
	my $data= $handle->_data;

	# Figure out count and offset, then either write or no-op (dry_run).
	$offset ||= 0;
	$count ||= length($buffer)-$offset;
	my $wrote= (defined $data->{dest_file})? syswrite( $data->{dest_file}, $buffer, $count, $offset||0 ) : $count;

	# digest only the bytes that we wrote
	if (defined $wrote and $wrote > 0) {
		local $!; # just in case
		$data->{wrote} += $wrote;
		$data->{digest}->add(substr($buffer, $offset, $wrote))
			if defined $data->{digest};
	}
	return $wrote;
}

sub _handle_seek {
	croak "Seek unsupported (for now)"
}

sub _handle_tell {
	my ($self, $handle)= @_;
	return $handle->_data->{wrote};
}


sub commit_write_handle {
	my ($self, $handle)= @_;
	my $data= $handle->_data;
	
	my $hash= defined $data->{hash}?
		$data->{hash}
		: $data->{digest}->hexdigest;
	
	my $temp_file= $data->{dest_file};
	if (defined $temp_file) {
		# Make sure all data committed
		close $temp_file
			or croak "while saving '$temp_file': $!";
	}
	
	return $self->_commit_file($temp_file, $hash, $data);
}

sub _commit_file {
	my ($self, $source_file, $hash, $flags)= @_;
	# Find the destination file name
	my $dest_name= $self->_path_for_hash($hash);
	# Only if we don't have it yet...
	if (-f $dest_name) {
		if ($flags->{stats}) {
			$flags->{stats}{dup_file_count}++;
		}
	}
	else {
		# link it into place
		# we check for missing directories after the first failure,
		#   in the spirit of keeping the common case fast.
		$flags->{dry_run}
			or link($source_file, $dest_name)
			or ($self->_add_missing_path($hash) and link($source_file, $dest_name))
			or croak "rename($source_file => $dest_name): $!";
		# record that we added a new hash, if stats enabled.
		if ($flags->{stats}) {
			$flags->{stats}{new_file_count}++;
			push @{ $flags->{stats}{new_files} ||= [] }, $hash;
		}
	}
	$hash;
}


sub put_file {
	my ($self, $file, $flags)= @_;

	# Copied logic from superclass, because we might not get there
	my $is_cas_file= ref $file && ref($file)->isa('DataStore::CAS::File');
	if ($flags->{reuse_hash} && $is_cas_file) {
		$flags->{known_hashes} ||= {};
		$flags->{known_hashes}{ $file->store->digest }= $file->hash;
	}

	# Here is where we detect opportunity to perform optimized hard-linking
	#  when copying to and from CAS implementations which are backed by
	#  plain files.
	if ($flags->{hardlink}) {
		my $hardlink_source= 
			($is_cas_file && $file->can('local_file') and length $file->local_file)? $file->local_file
			: (ref $file && ref($file)->isa('Path::Class::File'))? "$file"
			: (!ref $file)? $file
			: undef;
		if (defined $hardlink_source) {
			# Try hard-linking it.  If fails, (i.e. cross-device) fall back to regular behavior
			my $hash=
				try { $self->_put_hardlink($file, $hardlink_source, $flags) }
				catch { undef; };
			return $hash if defined $hash;
		}
	}
	# Else use the default implementation which opens and reads the file.
	goto \&DataStore::CAS::put_file;
}

sub _put_hardlink {
	my ($self, $file, $hardlink_source, $flags)= @_;

	# If we know the hash, try linking directly to the final name.
	my $hash= $flags->{known_hashes}{$self->digest};
	if (defined $hash) {
		$self->_commit_file($hardlink_source, $hash, $flags);
		return $hash;
	}

	# If we don't know the hash, we first link to a temp file, to find out
	# whether we can, and then calculate the hash, and then rename our link.
	# This way we can fall back to regular behavior without double-reading
	# the source file.
	
	# Use File::Temp to atomically get a unique filename, which we use as a prefix.
	my $temp_file= File::Temp->new( TEMPLATE => 'temp-XXXXXXXX', DIR => $self->path );
	my $temp_link= $temp_file."-lnk";
	link( $hardlink_source, $temp_link )
		or return undef;
	
	# success - we don't need to copy the file, just checksum it and rename.
	# use try/catch so we can unlink our tempfile
	return
		try {
			# Calculate hash
			open( my $handle, '<:raw', $temp_link ) or die "open: $!";
			my $digest= $self->_new_digest->addfile($handle);
			$hash= $digest->hexdigest;
			close $handle or die "close: $!";

			# link to final correct name
			$self->_commit_file($temp_link, $hash, $flags);
			unlink($temp_link);
			$hash;
		}
		catch {
			unlink($temp_link);
			undef;
		};
}


sub validate {
	my ($self, $hash)= @_;

	my $path= $self->_path_for_hash($hash);
	return undef unless -f $path;

	open (my $fh, "<:raw", $path)
		or return 0; # don't die.  Errors mean "not valid", even if it might be a permission issue
	my $hash2= try { $self->_new_digest->addfile($fh)->hexdigest } catch {''};
	return ($hash eq $hash2? 1 : 0);
}


sub open_file {
	my ($self, $file, $flags)= @_;
	my $mode= '<';
	$mode .= ':'.$flags->{layer} if ($flags && $flags->{layer});
	open my $fh, $mode, $file->local_file
		or croak "open: $!";
	return $fh;
}


sub _slurpdir {
	my ($path, $digits)= @_;
	opendir my $dh, $_[0] || die "opendir: $!";
	[ sort grep { length($_) eq $digits } readdir $dh ]
}
sub iterator {
	my ($self, $flags)= @_;
	$flags ||= {};
	my @length= ( $self->fanout_list, length($self->hash_of_null) );
	$length[-1] -= $_ for @length[0..($#length-1)];
	my $path= "".$self->path;
	my @dirstack= ( _slurpdir($path, $length[0]) );
	return sub {
		return undef unless @dirstack;
		while (1) {
			# back out of a directory hierarchy that we have finished
			while (!@{$dirstack[-1]}) {
				pop @dirstack; # back out of directory
				return undef unless @dirstack;
				shift @{$dirstack[-1]}; # remove directory name
			}
			# Build the name of the next file or directory
			my @parts= map { $_->[0] } @dirstack;
			my $fname= catfile( $path, @parts );
			# If a dir, descend into it
			if (-d $fname) {
				push @dirstack, _slurpdir($fname, $length[scalar @dirstack]);
			} else {
				shift @{$dirstack[-1]};
				# If a file at the correct depth, return it
				if ($#dirstack == $#length && -f $fname) {
					return join('', @parts);
				}
			}
		}
	};
}


sub delete {
	my ($self, $digest_hash, $flags)= @_;
	my $path= $self->_path_for_hash($digest_hash);
	if (-f $path) {
		unlink $path || die "unlink: $!"
			unless $flags && $flags->{dry_run};
		$flags->{stats}{delete_count}++
			if $flags && $flags->{stats};
		return 1;
	} else {
		$flags->{stats}{delete_missing}++
			if $flags && $flags->{stats};
		return 0;
	}
}

# This can be called as class or instance method.
# When called as an instance method, '$digest_name' is mandatory,
#   otherwise it is unneeded.
sub _new_digest {
	my ($self, $digest_name)= @_;
	Digest->new($digest_name || $self->digest);
}

sub _path_for_hash {
	my ($self, $hash)= @_;
	return catfile($self->path, ($hash =~ $self->_fanout_regex));
}

sub _add_missing_path {
	my ($self, $hash)= @_;
	my $str= $self->path;
	my @parts= ($hash =~ $self->_fanout_regex);
	pop @parts; # discard filename
	for (@parts) {
		$str= catdir($str, $_);
		next if -d $str;
		mkdir($str) or croak "mkdir($str): $!";
	}
	1;
}

package DataStore::CAS::Simple::File;
use strict;
use warnings;
use parent 'DataStore::CAS::File';


sub local_file { $_[0]{local_file} }
sub block_size { $_[0]{block_size} }

1; # End of File::CAS::Store::Simple

__END__

=pod

=head1 NAME

DataStore::CAS::Simple - Simple file/directory based CAS implementation

=head1 VERSION

version 0.020001

=head1 DESCRIPTION

This implementation of L<DataStore::CAS> uses a directory tree where the
filenames are the hexadecimal value of the digest hashes.  The files are
placed into directories named with a prefix of the digest hash to prevent
too many entries in the same directory (which is actually only a concern
on certain filesystems).

Opening a L<File|DataStore::CAS::File> returns a real perl filehandle, and
copying a File object from one instance to another is optimized by hard-linking
the underlying file.

  # This is particularly fast:
  $cas1= DataStore::CAS::Simple->new( path => 'foo' );
  $cas2= DataStore::CAS::Simple->new( path => 'bar' );
  $cas1->put( $cas2->get( $hash ) );

This class does not perform any sort of optimization on the storage of the
content, neither by combining commom sections of files nor by running common
compression algorithms on the data.

TODO: write DataStore::CAS::Compressor or DataStore::CAS::Splitter
for those features.

=head1 ATTRIBUTES

=head2 path

Read-only.  The filesystem path where the store is rooted.

=head2 digest

Read-only.  Algorithm used to calculate the hash values.  This can only be
set in the constructor when a new store is being created.  Default is C<SHA-1>.

=head2 fanout

Read-only.  Returns arrayref of pattern used to split digest hashes into
directories.  Each digit represents a number of characters from the front
of the hash which then become a directory name.

For example, C<[ 2, 2 ]> would turn a hash of "1234567890" into a path of
"12/34/567890".

=head2 fanout_list

Convenience accessor for C<@{ $cas-E<gt>fanout }>

=head2 copy_buffer_size

Number of bytes to copy at a time when saving data from a filehandle to the
CAS.  This is a performance hint, and the default is usually fine.

=head2 storage_format_version

Hashref of version information about the modules that created the store.
Newer library versions can determine whether the storage is using an old
format using this information.

=head2 _fanout_regex

Read-only.  A regex-ref which splits a digest hash into the parts needed
for the path name.
A fanout of C<[ 2, 2 ]> creates a regex of C</(.{2})(.{2})(.*)/>.

=head1 METHODS

=head2 new

  $class->new( \%params | %params )

Constructor.  It will load (and possibly create) a CAS Store.

If C<create> is specified, and C<path> refers to an empty directory, a fresh
store will be initialized.  If C<create> is specified and the directory is
already a valid CAS, C<create> is ignored, as well as C<digest> and
C<fanout>.

C<path> points to the cas directory.  Trailing slashes don't matter.
You might want to use an absolute path in case you C<chdir> later.

C<copy_buffer_size> initializes the respective attribute.

The C<digest> and C<fanout> attributes can only be initialized if
the store is being created.
Otherwise, it is loaded from the store's configuration.

C<ignore_version> allows you to load a Store even if it was created with a
newer version of the DataStore::CAS::Simple package that you are now using.
(or a different package entirely)

=for Pod::Coverage BUILD

=head2 create_store

  $class->create_store( %configuration | \%configuration )

Create a new store at a specified path.  Configuration must include C<path>,
and may include C<digest> and C<fanout>.  C<path> must be an empty writeable
directory, and it must exist.  C<digest> currently defaults to C<SHA-1>.
C<fanout> currently defaults to C<[1, 2]>, resulting in paths like "a/bc/defg".

This method can be called on classes or instances.

You may also specify C<create =E<gt> 1> in the constructor to implicitly call
this method using the relevant parameters you supplied to the constructor.

=head2 get

See L<DataStore::CAS/get> for details.

=head2 new_write_handle

See L<DataStore::CAS/new_write_handle> for details.

=head2 commit_write_handle

See L<DataStore::CAS/commit_write_handle> for details.

=head2 put

See L<DataStore::CAS/put> for details.

=head2 put_scalar

See L<DataStore::CAS/put_scalar> for details.

=head2 put_file

See L<DataStore::CAS/put_file> for details. In particular, heed the warnings
about using the 'hardlink' and 'reuse_hash' flag.

DataStore::CAS::Simple has special support for the flag 'hardlink'.  If your
source is a real file, or instance of L<DataStore::CAS::File> from another
DataStore::CAS::Simple, C<{ hardlink =E<gt> 1 }> will link to the file instead
of copying it.

=head2 validate

See L<DataStore::CAS/validate> for details.

=head2 open_file

See L<DataStore::CAS/open_file> for details.

=head2 iterator

See L<DataStore::CAS/iterator> for details.

=head2 delete

See L<DataStore::CAS/delete> for details.

=head1 FILE OBJECTS

File objects returned by DataStore::CAS::Simple have two additional attributes:

=head2 local_file

The filename of the disk file within DataStore::CAS::Simple's path which holds
the requested data.

=head2 block_size

The block_size parameter from C<stat()>, which might be useful for accessing
the file efficiently.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

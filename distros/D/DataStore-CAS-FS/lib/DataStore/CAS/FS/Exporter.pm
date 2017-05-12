package DataStore::CAS::FS::Exporter;
use 5.008;
use Moo;
use Try::Tiny;
use Carp;
use File::Spec::Functions 'catfile', 'catdir', 'splitpath', 'catpath';
use Fcntl ':mode';

our $VERSION= '0.011000';

# ABSTRACT: Copy files from DataStore::CAS::FS to real filesystem.


our %_flag_defaults;
BEGIN {
	%_flag_defaults= (
		die_on_unsupported    => 1,
		die_on_creation_error => 1,
		die_on_metadata_error => 1,
		utf8_filenames        => 1,
	);
	for (keys %_flag_defaults) {
		eval "sub $_ { \$_[0]{flags}{$_}= \$_[1] if \@_ > 1; \$_[0]{flags}{$_} }; 1" or die $@
	}
}
sub _flag_defaults {
	\%_flag_defaults;
}

has flags => ( is => 'rw', default => sub { {} } );
has unix_user_cache => ( is => 'rw', default => sub { {} } );
has unix_group_cache => ( is => 'rw', default => sub { {} } );


sub BUILD {
	my ($self, $args)= @_;
	my $flags= $self->flags;
	my $defaults= $self->_flag_defaults;
	for (keys %$defaults) {
		$flags->{$_}= delete $args->{$_}
			if exists $args->{$_};
		$flags->{$_}= $_flag_defaults{$_}
			unless defined $flags->{$_};
	}
	defined $defaults->{$_} || croak "Unknown flag: '$_'"
		for keys %$flags;
	$self->can($_) || croak "Unknown attribute: '$_'"
		for keys %$args;
}

sub export_tree {
	my ($self, $virt_path, $real_path)= @_;

	$virt_path->isa('DataStore::CAS::FS::Path')
		or croak "Virtual path must be an instance of DataStore::CAS::FS::Path";

	-e $real_path
		and croak "The destination path must not already exist";
	if (utf8::is_utf8($real_path)) {
		$self->utf8_filenames? utf8::encode($real_path) : utf8::downgrade($real_path);
	}
	$self->_extract_recursive($virt_path, $real_path);
	1;
}

sub _extract_recursive {
	my ($self, $src, $real_path)= @_;
	my $dirent= $src->dirent;
	my $dest_fh= $self->_create_dirent($dirent, $real_path);
	if ($dirent->type eq 'file') {
		# Copy file
		if (!defined $dirent->ref) {
			warn "File \"".$dirent->name."\" was not stored.  Exporting as empty file.\n";
		} elsif ($dirent->ref ne $src->filesystem->hash_of_null) {
			my $err;
			try {
				my $src_fh= $src->open;
				my ($buf, $got);
				while ($got= read($src_fh, $buf, 1024*1024)) {
					(print $dest_fh $buf) or die "write: $!\n";
				}
				defined $got or die "read: $!\n";
				close $src_fh or die "close: $!\n";
				close $dest_fh or die "close: $!\n";
			} catch {
				chomp( $err= "$_" );
			};
			$self->_handle_creation_error("copy to \"$real_path\": $err")
				if defined $err;
		}
	} elsif ($dirent->type eq 'dir') {
		for ($src->readdir) {
			my $sysname= "$_";
			$self->utf8_filenames? utf8::encode($sysname) : utf8::downgrade($sysname)
				if utf8::is_utf8($sysname);
			$self->_extract_recursive($src->path($_), File::Spec->catdir($real_path, $sysname))
		}
	}
	$self->_apply_metadata($dirent, $real_path);
}

sub _create_dirent {
	my ($self, $entry, $path)= @_;
	my $t= $entry->type;
	if ($t eq 'file') {
		open(my $dest_fh, '>:raw', $path)
			or $self->_handle_creation_error("open($path): $!");
		return $dest_fh;
	} elsif ($t eq 'dir') {
		mkdir $path
			or $self->_handle_creation_error("mkdir($path): $!");
	} elsif ($t eq 'symlink') {
		symlink $entry->ref, $path
			or $self->_handle_creation_error("symlink($path): $!");
	} elsif ($t eq 'blockdev' || $t eq 'chardev') {
		my ($major, $minor)= split /,/, $entry->ref;
		defined $major && length $major && defined $minor && length $minor
			or die "mknod($path): Invalid device notation \"".$entry->ref."\"\n";
		$self->_mknod($self, $path, $entry, $major, $minor);
	} elsif ($t eq 'pipe') {
		$self->_mknod($self, $path, $entry, 0, 0);
	} elsif ($t eq 'socket') {
		require Socket;
		my $sock;
		socket($sock, Socket::PF_UNIX(), Socket::SOCK_STREAM(), 0)
			&& bind($sock, sockaddr_un($path))
			or $self->_handle_creation_error("socket/bind($path): $!");
	} else {
		$self->_handle_creation_error("Unsupported directory entry type \"$t\" for $path");
	}
	return undef;
}

sub _apply_metadata {
	my ($self, $entry, $path)= @_;
	if (defined (my $mode= $entry->unix_mode)) {
		chmod($mode & ~Fcntl::S_IFMT(), $path)
			or $self->_handle_metadata_error("chmod($path): $!");
	}

	my ($uid, $gid)= ($entry->unix_uid, $entry->unix_gid);
	if (defined (my $u= $entry->unix_user)) {
		my $cache= $self->unix_user_cache;
		exists $cache->{$u}? (defined $cache->{$u} and ($uid= $cache->{$u}))
			: defined( $cache->{$u}= getgrnam($u) )? $uid= $cache->{$u}
			: $self->_handle_metadata_error("Can't resolve username '$u'");
	}
	if (defined (my $g= $entry->unix_group)) {
		my $cache= $self->unix_group_cache;
		exists $cache->{$g}? (defined $cache->{$g} and ($gid= $cache->{$g}))
			: defined( $cache->{$g}= getgrnam($g) )? $gid= $cache->{$g}
			: $self->_handle_metadata_error("Can't resolve username '$g'");
	}
	chown( (defined $uid? $uid : -1), (defined $gid? $gid : -1), $path )
		|| $self->_handle_metadata_error("chown($uid, $gid, $path): $!")
		if defined $uid || defined $gid;

	my $mtime= $entry->modify_ts;
	if (defined $mtime) {
		my $atime= $entry->access_ts;
		defined $atime or $atime= $mtime;
		utime($atime, $mtime, $path)
			or $self->_handle_metadata_error("utime($atime, $mtime, $path): $!");
	}
}

sub _handle_metadata_error {
	my ($self, $msg)= @_;
	die $msg."\n" if $self->{flags}{die_on_metadata_error};
	warn $msg."\n";
}

sub _handle_creation_error {
	my ($self, $msg)= @_;
	die $msg."\n" if $self->{flags}{die_on_creation_error};
	warn $msg."\n";
}

sub _mknod {
	my $fn= (try { require Unix::Mknod; 1; } catch { undef })? \&_mknod_perl
		: (`mknod --version` && $? == 0)? \&_mknod_system
		: \&_mknod_unsupported;
	no warnings 'redefine';
	*_mknod= $fn;
	goto $fn;
}

sub _mknod_perl {
	my ($self, $path, $entry, $major, $minor)= @_;
	my $mode= ($entry->type eq 'blockdev')? S_IFBLK|0600
		: ($entry->type eq 'chardev')? S_IFCHR|0600
		: ($entry->type eq 'pipe')? S_IFIFO|0600
		: die "Unsupported type ".$entry->type;
	0 == Unix::Mknod::mknod($path, $mode, Unix::Mknod::makedev($major, $minor))
		or $self->_handle_creation_error("mknod($path, $mode, ".Unix::Mknod::makedev($major, $minor)."): $!");
}

sub _mknod_system {
	my ($self, $path, $dirent, $major, $minor)= @_;
	if ($dirent->type eq 'pipe') {
		system('mkfifo', $path) == 0 || die "exec(mkfifo, $path): $!\n";
		$? == 0 || $self->_handle_creation_error("mkfifo($path) exited ".($? & 127? "on signal ".($? & 127) : "with ".($? >> 8)));
	} else {
		my $t= $dirent->type eq 'blockdev'? 'b' : 'c';
		system('mknod', $path, $t, $major, $minor) == 0 or die "exec(mknod, $path, $t, $major, $minor): $!\n";
		$? == 0 || $self->_handle_creation_error("mknod($path) exited ".($? & 127? "on signal ".($? & 127) : "with ".($? >> 8)));
	}
}

sub _mknod_unsupported {
	my ($self, $path)= @_;
	$self->die_on_unsupported?
		die "mknod($path): Module Unix::Mknod is not installed and mknod(1) is not in the PATH\n"
		: warn "Skipping mknod($path)\n";
}

1;

__END__

=pod

=head1 NAME

DataStore::CAS::FS::Exporter - Copy files from DataStore::CAS::FS to real filesystem.

=head1 VERSION

version 0.011000

=head1 SYNOPSIS

  my $cas_fs= DataStore::CAS::FS->new( ... );
  
  # Use default settings
  my $exporter= DataStore::CAS::FS::Exporter->new();
  $exporter->export_tree($cas_fs->path("/foo/bar"), "/foo/bar");

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head2 unix_user_cache

=head2 unix_group_cache

=head2 flags

=over

=item die_on_unsupported

Die if the exporter encounters a directory entry type which is unsupported on
the current platform, or for which there isn't an available Perl module to
create it.  (Such as unix sockets on Windows, or device nodes without package
Unix::Mknod installed, or unicode filenames under Windows without
Win32API::File)

=item die_on_metadata_error

Die if you asked the Exporter to preserve directory entry metadata (user,
group, permissions, times, etc) and one of the syscalls to apply that metadata
fails.

=item utf8_filenames

For system which use plain bytes for filenames (unix-like) this determines
whether filenames containing high-bit bytes should be flattened to UTF-8, or
latin-1 (or EBCDIC, but I have no access to such a system to test on, so don't
expect that to work)  You need to use the same setting for this flag in the
L<Importer|DataStore::CAS::FS::Importer>, or import+export might mangle your
filenames.

Since modern Unix is attempting to use UTF-8 to gain unicode filename support,
the default for this flag is C<1> in both modules.  If set to 0, you might
encounter filenames which can't be represented as latin-1, which throw an
error during export.

=back

=head1 METHODS

=head2 new

  my $exporter= $class->new( %attributes_and_flags )

The constructor accepts values for any of the official attributes.  It also
accepts all of the L<flag names|/flags>, and will move them into the C<flags>
attribute for you.

No arguments are required, and the defaults should work for most people.

=for Pod::Coverage BUILD

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Michael Conrad, and IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

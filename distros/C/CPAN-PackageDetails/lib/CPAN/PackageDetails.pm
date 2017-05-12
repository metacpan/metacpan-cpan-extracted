package CPAN::PackageDetails;
use strict;
use warnings;

use subs qw();
use vars qw($VERSION);

use Carp qw(carp croak cluck confess);
use Cwd;
use File::Basename;
use File::Spec::Functions;

BEGIN {
	$VERSION = '0.26';
	}

=head1 NAME

CPAN::PackageDetails - Create or read 02packages.details.txt.gz

=head1 SYNOPSIS

	use CPAN::PackageDetails;

	# read an existing file #####################
	my $package_details = CPAN::PackageDetails->read( $filename );

	my $count      = $package_details->count;

	my $records    = $package_details->entries->get_hash;

	foreach my $record ( @$records )
		{
		# See CPAN::PackageDetails::Entry too
		# print join "\t", map { $record->$_() } ('package name', 'version', 'path')
		print join "\t", map { $record->$_() } $package_details->columns_as_list;
		}

	# not yet implemented, but would be really, really cool eh?
	my $records    = $package_details->entries(
		logic   => 'OR',  # but that could be AND, which is the default
		package => qr/^Test::/, # or a string
		author  => 'OVID',      # case insenstive
		path    =>  qr/foo/,
		);

	# create a new file #####################
	my $package_details = CPAN::PackageDetails->new(
		file         => "02packages.details.txt",
		url          => "http://example.com/MyCPAN/modules/02packages.details.txt",
		description  => "Package names for my private CPAN",
		columns      => "package name, version, path",
		intended_for => "My private CPAN",
		written_by   => "$0 using CPAN::PackageDetails $CPAN::PackageDetails::VERSION",
		last_updated => CPAN::PackageDetails->format_date,
		allow_packages_only_once => 1,
		disallow_alpha_versions  => 1,
		);

	$package_details->add_entry(
		package_name => $package,
		version      => $package->VERSION;
		path         => $path,
		);

	print "About to write ", $package_details->count, " entries\n";

	$package_details->write_file( $file );

	 # OR ...

	$package_details->write_fh( \*STDOUT )

=head1 DESCRIPTION

CPAN uses an index file, F<02packages.details.txt.gz>, to map package names to
distribution files. Using this module, you can get a data structure of that
file, or create your own.

There are two parts to the F<02packages.details.txt.g>z: a header and the index.
This module uses a top-level C<CPAN::PackageDetails> object to control
everything and comprise an C<CPAN::PackageDetails::Header> and
C<CPAN::PackageDetails::Entries> object. The C<CPAN::PackageDetails::Entries>
object is a collection of C<CPAN::PackageDetails::Entry> objects.

For the most common uses, you don't need to worry about the insides
of what class is doing what. You'll call most of the methods on
the top-level  C<CPAN::PackageDetails> object and it will make sure
that it gets to the right place.

=head2 Methods

These methods are in the top-level object, and there are more methods
for this class in the sections that cover the Header, Entries, and
Entry objects.

=over 4

=item new

Create a new F<02packages.details.txt.gz> file. The C<default_headers>
method shows you which values you can pass to C<new>. For instance:

	my $package_details = CPAN::PackageDetails->new(
		url     => $url,
		columns => 'author, package name, version, path',
		)

If you specify the C<allow_packages_only_once> option with a true value
and you try to add that package twice, the object will die. See C<add_entry>
in C<CPAN::PackageDetails::Entries>.

If you specify the C<disallow_alpha_versions> option with a true value
and you try to add that package twice, the object will die. See C<add_entry>
in C<CPAN::PackageDetails::Entries>.

=cut

BEGIN {
my $class_counter = 0;
sub new {
	my( $class, %args ) = @_;

	my( $ref, $bless_class ) = do {
		if( exists $args{dbmdeep} ) {
			eval { require DBM::Deep };
			if( $@ ) {
				croak "You must have DBM::Deep installed and discoverable to use the dbmdeep feature";
				}
			my $ref = DBM::Deep->new(
				file => $args{dbmdeep},
				autoflush => 1,
				);
			croak "Could not create DBM::Deep object" unless ref $ref;
			my $single_class = sprintf "${class}::DBM%03d", $class_counter++;

			no strict 'refs';
			@{"${single_class}::ISA"} = ( $class , 'DBM::Deep' );
			( $ref, $single_class );
			}
		else {
			( {}, $class );
			}
		};

	my $self = bless $ref, $bless_class;

	$self->init( %args );

	$self;
	}
}

=item init

Sets up the object. C<new> calls this automatically for you.

=item default_headers

Returns the hash of header fields and their default values:

	file            "02packages.details.txt"
	url             "http://example.com/MyCPAN/modules/02packages.details.txt"
	description     "Package names for my private CPAN"
	columns         "package name, version, path"
	intended_for    "My private CPAN"
	written_by      "$0 using CPAN::PackageDetails $CPAN::PackageDetails::VERSION"
	last_updated    format_date()

In the header, these fields show up with the underscores turned into hyphens,
and the letters at the beginning or after a hyphen are uppercase.

=cut

BEGIN {
# These methods live in the top level and delegate interfaces
# so I need to intercept them at the top-level and redirect
# them to the right delegate
my %Dispatch = (
		header  => { map { $_, 1 } qw(
			default_headers get_header set_header header_exists
			columns_as_list
			) },
		entries => { map { $_, 1 } qw(
			add_entry count as_unique_sorted_list already_added
			allow_packages_only_once disallow_alpha_versions
			get_entries_by_package get_entries_by_version
			get_entries_by_path get_entries_by_distribution
			allow_suspicious_names get_hash
			) },
	#	entry   => { map { $_, 1 } qw() },
		);

my %Dispatchable = map { #inverts %Dispatch
	my $class = $_;
	map { $_, $class } keys %{$Dispatch{$class}}
	} keys %Dispatch;

sub can {
	my( $self, @methods ) = @_;

	my $class = ref $self || $self; # class or instance

	foreach my $method ( @methods ) {
		next if
			defined &{"${class}::$method"} ||
			exists $Dispatchable{$method}  ||
			$self->header_exists( $method );
		return 0;
		}

	return 1;
	}

sub AUTOLOAD {
	my $self = shift;


	our $AUTOLOAD;
	carp "There are no AUTOLOADable class methods: $AUTOLOAD" unless ref $self;
	( my $method = $AUTOLOAD ) =~ s/.*:://;

	if( exists $Dispatchable{$method} ) {
		my $delegate = $Dispatchable{$method};
		return $self->$delegate()->$method(@_)
		}
	elsif( $self->header_exists( $method ) ) {
		return $self->header->get_header( $method );
		}
	else {
		carp "No such method as $method!";
		return;
		}
	}
}

BEGIN {
my %defaults = (
	file            => "02packages.details.txt",
	url             => "http://example.com/MyCPAN/modules/02packages.details.txt",
	description     => "Package names for my private CPAN",
	columns         => "package name, version, path",
	intended_for    => "My private CPAN",
	written_by      => "$0 using CPAN::PackageDetails $CPAN::PackageDetails::VERSION",

	header_class    => 'CPAN::PackageDetails::Header',
	entries_class   => 'CPAN::PackageDetails::Entries',
	entry_class     => 'CPAN::PackageDetails::Entry',

	allow_packages_only_once => 1,
	disallow_alpha_versions  => 0,
	allow_suspicious_names   => 0,
	);

sub init
	{
	my( $self, %args ) = @_;

	my %config = ( %defaults, %args );

	# we'll delegate everything, but also try to hide the mess from the user
	foreach my $key ( map { "${_}_class" } qw(header entries entry) ) {
		$self->{$key}  = $config{$key};
		delete $config{$key};
		}

	foreach my $class ( map { $self->$_ } qw(header_class entries_class entry_class) ) {
		eval "require $class";
		}

	# don't initialize things if they are already there. For instance,
	# if we read an existing DBM::Deep file
	$self->{entries} = $self->entries_class->new(
		entry_class              => $self->entry_class,
		columns                  => [ split /,\s+/, $config{columns} ],
		allow_packages_only_once => $config{allow_packages_only_once},
		allow_suspicious_names   => $config{allow_suspicious_names},
		disallow_alpha_versions  => $config{disallow_alpha_versions},
		) unless exists $self->{entries};

	$self->{header}  = $self->header_class->new(
		_entries => $self->entries,
		) unless exists $self->{header};


	foreach my $key ( keys %config )
		{
		$self->header->set_header( $key, $config{$key} );
		}

	$self->header->set_header(
		'last_updated',
		$self->header->format_date
		);

	}

}

=item read( FILE )

Read an existing 02packages.details.txt.gz file.

While parsing, it modifies the field names to map them to Perly
identifiers. The field is lowercased, and then hyphens become
underscores. For instance:

	Written-By ---> written_by

=cut

sub read {
	my( $class, $file, %args ) = @_;

	unless( defined $file ) {
		carp "Missing argument!";
		return;
		}

	require IO::Uncompress::Gunzip;

	my $fh = IO::Uncompress::Gunzip->new( $file ) or do {
		no warnings;
		carp "Could not open $file: $IO::Compress::Gunzip::GunzipError\n";
		return;
		};

	my $self = $class->_parse( $fh, %args );

	$self->{source_file} = $file;

	$self;
	}

=item source_file

Returns the original file path for objects created through the
C<read> method.

=cut

sub source_file { $_[0]->{source_file} }

sub _parse {
	my( $class, $fh, %args ) = @_;

	my $package_details = $class->new( %args );

	while( <$fh> ) { # header processing
		last if /\A\s*\Z/;
		chomp;
		my( $field, $value ) = split /\s*:\s*/, $_, 2;

		$field = lc( $field || '' );
		$field =~ tr/-/_/;

		carp "Unknown field value [$field] at line $.! Skipping..."
			unless 1; # XXX should there be field name restrictions?
		$package_details->set_header( $field, $value );
		}

	my @columns = $package_details->columns_as_list;
	while( <$fh> ) { # entry processing
		chomp;
		my @values = split; # this could be in any order based on columns field.
		$package_details->add_entry(
			map { $columns[$_], $values[$_] } 0 .. $#columns,
			)
		}

	$package_details;
	}

=item write_file( OUTPUT_FILE )

Formats the object as a string and writes it to a temporary file and
gzips the output. When everything is complete, it renames the temporary
file to its final name.

C<write_file> carps and returns nothing if you pass it no arguments, if
it cannot open OUTPUT_FILE for writing, or if it cannot rename the file.

=cut

sub write_file {
	my( $self, $output_file ) = @_;

	unless( defined $output_file ) {
		carp "Missing argument!";
		return;
		}

	require IO::Compress::Gzip;

	my $fh = IO::Compress::Gzip->new( "$output_file.$$" ) or do {
		carp "Could not open $output_file.$$ for writing: $IO::Compress::Gzip::GzipError";
		return;
		};

	$self->write_fh( $fh );
	$fh->close;

	unless( rename "$output_file.$$", $output_file ) {
		carp "Could not rename temporary file to $output_file!\n";
		return;
		}

	return 1;
	}

=item write_fh( FILEHANDLE )

Formats the object as a string and writes it to FILEHANDLE

=cut

sub write_fh {
	my( $self, $fh ) = @_;

	print $fh $self->header->as_string, $self->entries->as_string;
	}

=item check_file( FILE, CPAN_PATH )

This method takes an existing F<02packages.details.txt.gz> named in FILE and
the the CPAN root at CPAN_PATH (to append to the relative paths in the
index), then checks the file for several things:

	1. That there are entries in the file
	2. The number of entries matches those declared in the Line-Count header
	3. All paths listed in the file exist under CPAN_PATH
	4. All distributions under CPAN_PATH have an entry (not counting older versions)

If any of these checks fail, C<check_file> croaks with a hash reference
with these keys:

	# present in every error object
	filename                the FILE you passed in
	cpan_path               the CPAN_PATH you passed in
	cwd                     the current working directory
	error_count

	# if FILE is missing
	missing_file          exists and true if FILE doesn't exist

	# if the entry count in the file is wrong
	# that is, the actual line count and header disagree
	entry_count_mismatch    true
	line_count              the line count declared in the header
	entry_count             the actual count

	# if some distros in CPAN_HOME are missing in FILE
	missing_in_file         anonymous array of missing paths

	# if some entries in FILE are missing the file in CPAN_HOME
	missing_in_repo         anonymous array of missing paths

=cut

sub ENTRY_COUNT_MISMATCH () { 1 }
sub MISSING_IN_REPO      () { 2 }
sub MISSING_IN_FILE      () { 3 }

sub check_file {
	my( $either, $file, $cpan_path ) = @_;

	# works with a class or an instance. We have to create a new
	# instance, so we need the class. However, I'm concerned about
	# subclasses, so if the higher level application just has the
	# object, and maybe from a class I don't know about, they should
	# be able to call this method and have it end up here if they
	# didn't override it. That is, don't encourage them to hard code
	# a class name
	my $class = ref $either || $either;

	# file exists
	my $error = {
		error_count => 0,
		cpan_path   => $cpan_path,
		filename    => $file,
		cwd         => cwd(),
		};
	unless( -e $file ) {
		$error->{missing_file}         = 1;
		$error->{error_count}         +=  1;
		}

	# file is gzipped

	# check header # # # # # # # # # # # # # # # # # # #
	my $packages = $class->read( $file );

	# count of entries in non-zero # # # # # # # # # # # # # # # # # # #

	my $header_count = $packages->get_header( 'line_count' );
	my $entries_count = $packages->count;

	unless( $header_count ) {
		$error->{entry_count_mismatch} = 1;
		$error->{line_count}           = $header_count;
		$error->{entry_count}          = $entries_count;
		$error->{error_count}         +=  1;
		}

	unless( $header_count == $entries_count ) {
		$error->{entry_count_mismatch} = 1;
		$error->{line_count}           = $header_count;
		$error->{entry_count}          = $entries_count;
		$error->{error_count}         +=  1;
		}

	if( $cpan_path ) {
		my $missing_in_file = $packages->check_for_missing_dists_in_file( $cpan_path );
		my $missing_in_repo = $packages->check_for_missing_dists_in_repo( $cpan_path );

		$error->{missing_in_file}  =  $missing_in_file if @$missing_in_file;
		$error->{missing_in_repo}  =  $missing_in_repo if @$missing_in_repo;
		$error->{error_count}     += @$missing_in_file  + @$missing_in_repo;
		}

	croak $error if $error->{error_count};

	return 1;
	}



=item check_for_missing_dists_in_repo( CPAN_PATH )

Given an object and a CPAN_PATH, return an anonymous array of the
distributions in the object that are not in CPAN_PATH. That is,
complain when the object has extra distributions.

C<check_file> calls this for you and adds the result to its
error output.

=cut

sub check_for_missing_dists_in_repo {
	my( $packages, $cpan_path ) = @_;

	my @missing;
	my( $entries ) = $packages->as_unique_sorted_list;
	foreach my $entry ( @$entries ) {
		my $path = $entry->path;

		my $native_path = catfile( $cpan_path, split m|/|, $path );

		push @missing, $path unless -e $native_path;
		}

	return \@missing;
	}

=item check_for_missing_dists_in_file( CPAN_PATH )

Given an object and a CPAN_PATH, return an anonymous array of the
distributions in CPAN_PATH that do not show up in the object. That is,
complain when the object doesn't have all the dists.

C<check_file> calls this for you and adds the result to its
error output.

=cut

sub check_for_missing_dists_in_file {
	my( $packages, $cpan_path ) = @_;

	my $dists = $packages->_get_repo_dists( $cpan_path );

	$packages->_filter_older_dists( $dists );

	my %files = map { $_, 1 } @$dists;
	use Data::Dumper;

	my( $entries ) = $packages->as_unique_sorted_list;

	foreach my $entry ( @$entries ) {
		my $path = $entry->path;
		my $native_path = catfile( $cpan_path, split m|/|, $path );
		delete $files{$native_path};
		}

	[ keys %files ];
	}

sub _filter_older_dists {
	my( $self, $array ) = @_;

	my %Seen;
	my @order;
	require  CPAN::DistnameInfo;
	foreach my $path ( @$array ) {
		my( $basename, $directory, $suffix ) = fileparse( $path, qw(.tar.gz .tgz .zip .tar.bz2) );
		my( $name, $version, $developer ) = CPAN::DistnameInfo::distname_info( $basename );
		my $tuple = [ $path, $name, $version ];
		push @order, $name;

		   # first branch, haven't seen the distro yet
		   if( ! exists $Seen{ $name } )        { $Seen{ $name } = $tuple }
		   # second branch, the version we see now is greater than before
		elsif( $Seen{ $name }[2] lt $version )  { $Seen{ $name } = $tuple }
		   # third branch, nothing. Really? Are you sure there's not another case?
		else                                   { () }
		}

	@$array = map {
		if( exists $Seen{$_} ) {
			my $dist = $Seen{$_}[0];
			delete $Seen{$_};
			$dist;
			}
		else {
			()
			}
		} @order;

	return 1;
	}


sub _distname_info {
	my $file = shift or return;

	my ($dist, $version) = $file =~ /^
		(                          # start of dist name
			(?:
				[-+.]*

				(?:
					[A-Za-z0-9]+
						|
					(?<=\D)_
						|
					_(?=\D)
				)*

	 			(?:
					[A-Za-z]
					(?=
						[^A-Za-z]
						|
						$
					)
						|
					\d
					(?=-)
	 			)

	 			(?<!
	 				[._-][vV]
	 			)
			)+
		)                          # end of dist name

		(                          # start of version
		.*
		)                          # end of version
	$/xs or return ($file, undef, undef );

	$dist =~ s/-undef\z// if ($dist =~ /-undef\z/ and ! length $version);

	# Catch names like Unicode-Collate-Standard-V3_1_1-0.1
	# where the V3_1_1 is part of the distname
	if ($version =~ /^(-[Vv].*)-(\d.*)/) {
		$dist    .= $1;
		$version  = $2;
		}

	$version = $1            if !length $version and $dist =~ s/-(\d+\w)$//;

	$version = $1 . $version if $version =~ /^\d+$/ and $dist =~ s/-(\w+)$//;

	if( $version =~ /\d\.\d/ ) { $version =~ s/^[-_.]+// }
	else                       { $version =~ s/^[-_]+//  }

	# deal with versions with extra information
	$version =~ s/-build\d+.*//;
	$version =~ s/-DRW.*//;

	# deal with perl versions, merely to see if it is a dev version
	my $dev;
	if( length $version ) {
		$dev = do {
			if ($file =~ /^perl-?\d+\.(\d+)(?:\D(\d+))?(-(?:TRIAL|RC)\d+)?$/) {
				 1 if (($1 > 6 and $1 & 1) or ($2 and $2 >= 50)) or $3;
				}
			elsif ($version =~ /\d\D\d+_\d/) {
				1;
				}
			};
		}
	else {
		$version = undef;
		}

	($dist, $version, $dev);
	}

sub _get_repo_dists {
	my( $self, $cpan_home ) = @_;

	my @files = ();

	use File::Find;

	my $wanted = sub {
		push @files,
			File::Spec::Functions::canonpath( $File::Find::name )
				if m/\.(?:tar\.gz|tgz|zip)\z/
			};

	find( $wanted, $cpan_home );

	return \@files;
	}

sub DESTROY {}

=back


=head3 Methods in CPAN::PackageDetails

=over 4

=item header_class

Returns the class that C<CPAN::PackageDetails> uses to create
the header object.

=cut

sub header_class { $_[0]->{header_class} }

=item header

Returns the header object.

=cut

sub header { $_[0]->{header} }

=back

=head3 Methods in CPAN::PackageDetails::Header

=over 4

=cut

=back

=head2 Entries

Entries are the collection of the items describing the package details.
It comprises all of the Entry object.

=head3 Methods is CPAN::PackageDetails

=over 4

=item entries_class

Returns the class to use for the Entries object.

To use a different Entries class, tell C<new> which class you want to use
by passing the C<entries_class> option:

	CPAN::PackageDetails->new(
		...,
		entries_class => $class,
		);

Note that you are responsible for loading the right class yourself.

=item count

Returns the number of entries.

This dispatches to the C<count> in CPAN::PackageDetails::Entries. These
are the same:

	$package_details->count;

	$package_details->entries->count;

=cut

sub entries_class { $_[0]->{entries_class} }

=item entries

Returns the entries object.

=cut

sub entries { $_[0]->{entries} }

=item entry_class

Returns the class to use for each Entry object.

To use a different Entry class, tell C<new> which class you want to use
by passing the C<entry_class> option:

	CPAN::PackageDetails->new(
		...,
		entry_class => $class,
		)

Note that you are responsible for loading the right class yourself.

=cut

sub entry_class { $_[0]->{entry_class} }

sub _entries { $_[0]->{_entries} }

=back

=head1 TO DO


=head1 SEE ALSO


=head1 SOURCE AVAILABILITY

This source is in Github:

	http://github.com/briandfoy/cpan-packagedetails

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;

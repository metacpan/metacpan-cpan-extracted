package CPAN::Cpanorg::Auxiliary;
use 5.14.0;
use warnings;
our $VERSION = '0.03';
use Carp;
use Cwd;
use File::Basename qw(basename dirname);
use File::Spec;
use JSON ();
use LWP::Simple qw(get);
use Path::Tiny;
#use Data::Dump qw(dd pp);

=head1 NAME

CPAN::Cpanorg::Auxiliary - Methods used in cpan.org infrastructure

=head1 USAGE

    use CPAN::Cpanorg::Auxiliary;

=head1 DESCRIPTION

The objective of this library is to provide methods which can be used to write
replacements for programs used on the CPAN master server and stored in
github.com in the F<perlorg/cpanorg> and F<devel/cpanorg-generators>
repositories.

In particular, each of those repositories has an executable program with
subroutines identical, or nearly so, to subroutines found in a program in the
other.  Those programs are:

=over 4

=item * L<cpanorg-generators: bin/perl-sorter.pl|https://github.com/devel/cpanorg-generators/blob/master/bin/perl-sorter.pl>

=item * L<cpanorg: bin/cpanorg_perl_releases|https://github.com/perlorg/cpanorg/blob/master/bin/cpanorg_perl_releases>

=back

By extracting these subroutines into a single package, we hope to improve the
maintainability of code running on the CPAN infrastructure.

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

F<CPAN::Cpanorg::Auxiliary> constructor.  Primarily used to check for the
presence of certain directories and files on the server.  Also stores certain
values that are currently hard-coded in various methods in
F<perl-sorter.pl> and F<cpanorg_per_releases>.

=item * Arguments

    my $self = CPAN::Cpanorg::Auxiliary->new({});

Hash reference, required.  Elements in that hash include:

=over 4

=item * C<path>

Absolute path to the directory on the server which serves as the "top-level"
of the infrastructure.  Beneath this directory we expect to find these
directories already in existence:

    ./CPAN
    ./CPAN/src
    ./CPAN/src/5.0
    ./CPAN/authors
    ./CPAN/authors/id
    ./content
    ./data

=item * C<verbose>

If provided with a Perl-true value, all methods produce extra output on
F<STDOUT> when run.  (However, no methods are yet coded for extra output.)

=item * C<versions_json>

String holding the basename of a file to be created (or regenerated) on server
holding metadata in JSON format about all releases of F<perl>.  Optional;
defaults to C<perl_version_all.json>.

=item * C<search_api_url>

String holding the URL for making an API call to get metadata about all
releases of F<perl>.  Optional; defaults to
C<http://search.cpan.org/api/dist/perl>.

=back

=item * Return Value

F<CPAN::Cpanorg::Auxiliary> object.

=item * Comment

=back


=cut

sub new {
    my ($class, $args) = @_;

    croak "Argument to constructor must be hashref"
        unless defined $args and ref($args) eq 'HASH';

    my @required_args = ( qw| path | );
    my @optional_args = ( qw| verbose versions_json search_api_url | );
    my %valid_args = map {$_ => 1} (@required_args, @optional_args);
    my @invalid_args_seen = ();
    for my $k (keys %{$args}) {
        push @invalid_args_seen, $k unless $valid_args{$k};
    }
    croak "Invalid elements passed to constructor: @invalid_args_seen"
        if @invalid_args_seen;

    for my $el (@required_args) {
        croak "'$el' not found in elements passed to constructor"
            unless exists $args->{$el};
    }
    croak "Could not locate directory '$args->{path}'" unless (-d $args->{path});

    my %data = map { $_ => $args->{$_} } keys %{$args};
    $data{cwd} = cwd();
    $data{versions_json} ||= 'perl_version_all.json';
    $data{search_api_url} ||= "http://search.cpan.org/api/dist/perl";
    $data{five_url} = "http://www.cpan.org/src/5.0/";

    my %dirs_required = (
        CPANdir     => [ $data{path}, qw| CPAN | ],
        srcdir      => [ $data{path}, qw| CPAN src | ],
        fivedir     => [ $data{path}, qw| CPAN src 5.0 | ],
        authorsdir  => [ $data{path}, qw| CPAN authors | ],
        iddir       => [ $data{path}, qw| CPAN authors id | ],
        contentdir  => [ $data{path}, qw| content | ],
        datadir     => [ $data{path}, qw| data | ],
    );
    my @dirs_required = map { File::Spec->catdir(@{$_}) } values %dirs_required;
    my @dirs_missing = ();
    for my $dir (@dirs_required) {
        push @dirs_missing, $dir unless -d $dir;
    }
    my $death_message = 'Could not locate required directories:';
    for my $el (@dirs_missing) {
        $death_message .= "\n  $el";
    }
    croak $death_message if @dirs_missing;

    for my $dir (keys %dirs_required) {
        $data{$dir} = File::Spec->catdir(@{$dirs_required{$dir}});
    }
    $data{path_versions_json} = File::Spec->catfile(
        $data{datadir}, $data{versions_json});

    return bless \%data, $class;
}

=head2 C<fetch_perl_version_data()>

=over 4

=item * Purpose

Compares JSON data found on disk to result of API call to CPAN for 'perl' distribution.

=item * Arguments

None at the present time.

=item * Return Value

List of two array references:

=over 4

=item *

List of hash references, one per stable perl release.

=item *

List of hash references, one per developmental or RC perl release.

=back

Side effect:  Guarantees existence of file F<data/perl_version_all.json>
beneath the top-level directory.

=item * Comment

Assumes existence of subdirectory F<data/> beneath current working directory.

=back

=cut

sub fetch_perl_version_data {
    my $self = shift;

    # See what we have on disk
    my $disk_json = path($self->{path_versions_json})->slurp_utf8
        if -r $self->{path_versions_json};

    my $cpan_json = $self->make_api_call;

    if ( $cpan_json eq $disk_json ) {
        # Data has not changed so don't need to do anything
        return;
    }
    else {
        # Save for next fetch
        $self->print_file( $cpan_json );
    }

    my $json = JSON->new->pretty(1);
    my $data = $json->decode($cpan_json);

    my @perls;
    my @testing;
    foreach my $module ( @{ $data->{releases} } ) {
        #next unless $module->{authorized} eq 'true';
        #next unless $module->{authorized};

        my $version = $module->{version};

        $version =~ s/-(?:RC|TRIAL)\d+$//;
        $module->{version_number} = $version;

        my ( $major, $minor, $iota ) = split( '[\._]', $version );
        $module->{version_major} = $major;

        # Silence one warning generated when processing the perl release whose
        # distvname was 'perl-5.6-info'
        no warnings 'numeric';
        $module->{version_minor} = int($minor);
        use warnings;

        $module->{version_iota}  = int( $iota || '0' );

        $module->{type}
            = $module->{status} eq 'testing'
            ? 'Devel'
            : 'Maint';

        # TODO: Ask - please add some validation logic here
        # so that on live it checks this exists
        $module->{zip_file} = $module->{distvname} . '.tar.gz';
        $module->{url}      = $self->{five_url} . $module->{zip_file};

        ( $module->{released_date}, $module->{released_time} )
            = split( 'T', $module->{released} );

        next if $major < 5;

        if ( $module->{status} eq 'stable' ) {
            push @perls, $module;
        }
        else {
            push @testing, $module;
        }
    }
    $self->{perl_versions} = \@perls;
    $self->{perl_testing} = \@testing;
}

=head2 C<add_release_metadata()>

=over 4

=item * Purpose

Enhance object's data structures with metadata about perl releases.

=item * Arguments

None.

=item * Return Value

None.

=back

=cut

sub add_release_metadata {
    my $self = shift;

    chdir $self->{CPANdir} or croak "Unable to chdir to $self->{CPANdir}";

    # check disk for files
    foreach my $perl ( @{$self->{perl_versions}}, @{$self->{perl_testing}} ) {
        my $id = $perl->{cpanid};

        if ( $id =~ /^(.)(.)/ ) {
            my $path     = "authors/id/$1/$1$2/$id";
            my $fileroot = "$path/" . $perl->{distvname};
            my @files    = glob("${fileroot}.*tar.*");

            die "Could not find perl ${fileroot}.*" unless scalar(@files);

            $perl->{files} = [];
            # The file_meta() sub in bin/perl-sorter.pl assumes the presence
            # of checksum files for each perl release.
            foreach my $file (@files) {
                my $ffile = File::Spec->catfile($self->{CPANdir}, $file);
                my $meta = file_meta($ffile);
                push( @{ $perl->{files} }, $meta );
            }
        }
    }
}

=head2 C<write_security_files_and_symlinks()>

=over 4

=item * Purpose

For each perl release, create three security files: C<md5 sha1 sha256>.  Create symlinks from the F<src> and F<src/5.0> directories to the originals underneath the release manager's directory under F<authors/id>.

=item * Arguments

None.

=item * Return Value

Returns true value upon success.

=back

=cut

sub write_security_files_and_symlinks {
    my $self = shift;

    chdir $self->{srcdir} or croak "Unable to chdir to $self->{srcdir}";

    foreach my $perl ( @{$self->{perl_versions}}, @{$self->{perl_testing}} ) {

        # For a perl e.g. perl-5.12.4-RC1
        # create or symlink:
        foreach my $file ( @{ $perl->{files} } ) {

            my $filename = $file->{file};
            my $out = "5.0/" . $file->{filename};

            foreach my $security (qw(md5 sha1 sha256)) {

                print_file_if_different( "${out}.${security}.txt",
                    $file->{$security} );
            }

            my $target;
            my ($authors_dir) = $file->{filedir} =~ s/^.*?(authors.*)$/$1/r;
            $target = File::Spec->catfile('..', '..', $authors_dir, $file->{filename});
            create_symlink( $target, $out );

            # only link stable versions directly from src/
            next unless $perl->{status} eq 'stable';
            $target = File::Spec->catfile('..', $authors_dir, $file->{filename});
            create_symlink( $target, $file->{filename} );
        }
    }
    return 1;
}

=head2 C<create_latest_only_symlinks()>

=over 4

=item * Purpose

Create two symlinks in F<src> directory:

    /src/latest.tar....
    /src/stable.tar....

One symlink for each compression format for a particular release.

=item * Arguments

None.

=item * Return Value

Returns true value upon success.

=item * Comment

Per L<https://www.cpan.org/src/> (retrieved Jun 10 2018):
The "latest" and "stable" are now just aliases for "maint", and "maint" in
turn is the maintenance branch with the largest release number. 

=back

=cut

sub create_latest_only_symlinks {
    my $self = shift;

    chdir $self->{srcdir} or croak "Unable to chdir to $self->{srcdir}";

    my ($perl_versions, $perl_testing) = $self->get_perl_versions_and_testing;
    my $latest_perl_version
        = extract_first_perl_version_in_list($perl_versions);

    my $latest = sort_versions( [ values %{$latest_perl_version} ] )->[0];

    foreach my $file ( @{ $latest->{files} } ) {

        my ($authors_dir) = $file->{filedir} =~ s/^.*?(authors.*)$/$1/r;
        my $out_latest
            = $file->{file} =~ /bz2/
            ? "latest.tar.bz2"
            : "latest.tar.gz";

        my $target = File::Spec->catfile('..', $authors_dir, $file->{filename});
        create_symlink( $target, $out_latest );

        my $out_stable
            = $file->{file} =~ /bz2/
            ? "stable.tar.bz2"
            : "stable.tar.gz";

        create_symlink( $target, $out_stable );
    }
    
    chdir $self->{cwd} or croak "Could not change back to starting point";
    return 1;
}

##### INTERNAL METHODS #####

# make_api_call(): Called within fetch_perl_version_data()

sub make_api_call {
    my $self = shift;
    my $cpan_json = get($self->{search_api_url});
    die "Unable to fetch $self->{search_api_url}" unless $cpan_json;
    return $cpan_json;
}

# get_perl_versions_and_testing(): Called within create_latest_only_symlinks()

sub get_perl_versions_and_testing {
    my $self = shift;
    return ( $self->{perl_versions} || {}, $self->{perl_testing} || {} );
}


=head2 C<print_file()>

=over 4

=item * Purpose

Write out data from an array reference, here, data from the result of an HTTP
F<get> call which returns data in JSON format.

=item * Arguments

    $self->print_file($file, $array_ref);

Two arguments:  basename of a file to be written to (implicitly, in a subdirectory called F<data/>); reference to an array of JSON elements.

=item * Return Value

Implicitly returns true value upon success.  Dies otherwise.

=item * Comment

=back

=cut

sub print_file {
    my ( $self, $data ) = @_;
    path($self->{path_versions_json})->spew_utf8($data)
        or croak "Could not write $self->{path_versions_json}";
}

##### INTERNAL SUBROUTINES #####

=head2 file_meta

    my $meta = file_meta($file);

	print $meta->{file};
	print $meta->{filename};
	print $meta->{filedir};
    print $meta->{md5};
    print $meta->{sha256};
    print $meta->{mtime};
    print $meta->{sha1};

Get or calculate meta information about a file

=cut

sub file_meta {
    my $file     = shift;
    my $filename = basename($file);
    my $dir      = dirname($file);
    my $checksum = File::Spec->catfile($dir, 'CHECKSUMS');

    # The CHECKSUM file has already calculated
    # lots of this so use that
    my $cksum;
    unless ( defined( $cksum = do $checksum ) ) {
        die qq[Checksums file "$checksum" not found\n];
    }

    # Calculate the sha1
    my $sha1;
    if ( open( my $fh, "openssl sha1 $file |" ) ) {
        while (<$fh>) {
            if (/^SHA1\(.+?\)= ([0-9a-f]+)$/) {
                $sha1 = $1;
                last;
            }
        }
    }
    die qq[Failed to compute sha1 for $file\n] unless defined $sha1;

    return {
        file     => $file,
        filedir  => $dir,
        filename => $filename,
        mtime    => ( stat($file) )[9],
        md5      => $cksum->{$filename}->{md5},
        sha256   => $cksum->{$filename}->{sha256},
        sha1     => $sha1,
    };
}

sub print_file_if_different {
    my ( $file, $data ) = @_;

    if ( -r $file ) {
        my $content = path($file)->slurp_utf8;
        return if $content eq $data;
    }

    path($file)->spew_utf8($data)
        or die "Could not write $file: $!";
}

=head2 create_symlink

    create_symlink($oldfile, $newfile);

Will unlink $newfile if it already exists and then create
the symlink.

=cut

sub create_symlink {
    my ( $oldfile, $newfile ) = @_;

    # Clean out old symlink if it does not point to correct location
    if ( -l $newfile && readlink($newfile) ne $oldfile ) {
        unlink($newfile);
    }
    symlink( $oldfile, $newfile ) unless -l $newfile;
}

=head2 C<sort_versions()>

=over 4

=item * Purpose

Produce appropriately sorted list of Perl releases.

=item * Arguments

    my $latest = sort_versions( [ values %{$latest_per_version} ] )->[0];

=item * Return Value

=item * Comment

Call last.

=back

=cut

sub sort_versions {
    my $list = shift;

    my @sorted = sort {
               $b->{version_major} <=> $a->{version_major}
            || int( $b->{version_minor} ) <=> int( $a->{version_minor} )
            || $b->{version_iota} <=> $a->{version_iota}
    } @{$list};

    return \@sorted;

}

=head2 C<extract_first_perl_version_in_list()>

=over 4

=item * Purpose

=item * Arguments

=item * Return Value

=item * Comment

=back

=cut

sub extract_first_perl_version_in_list {
    my $versions = shift;

    my $lookup = {};
    foreach my $version ( @{$versions} ) {
        my $minor_version = $version->{version_major} . '.'
            . int( $version->{version_minor} );

        $lookup->{$minor_version} = $version
            unless $lookup->{$minor_version};
    }
    return $lookup;
}

1;

__END__


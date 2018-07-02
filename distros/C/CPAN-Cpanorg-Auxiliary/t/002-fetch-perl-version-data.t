# t/002-fetch-perl-version-data.t
use 5.14.0;
use warnings;
use CPAN::Cpanorg::Auxiliary;
use Carp;
use Cwd;
use File::Copy;
use File::Spec;
use Test::More;
use lib ('./t/testlib');
use Helpers qw(basic_test_setup);
#use Data::Dump qw(dd pp);

my $cwd = cwd();

{
    my $tdir = basic_test_setup($cwd);
    my $mockdata_from = File::Spec->catfile($cwd, 't', 'mock.perl_version_all.json');
    my $mockdata_to   = File::Spec->catfile($tdir, 'data', 'perl_version_all.json');
    copy $mockdata_from => $mockdata_to
        or croak "Unable to copy $mockdata_from for testing";

    my $CPANdir = File::Spec->catdir($tdir, qw( CPAN ));
    ok(-d $CPANdir, "Located directory '$CPANdir'");
    my $sample_tarball = File::Spec->catfile($tdir,
        qw( CPAN authors id S SH SHAY perl-5.26.2-RC1.tar.gz ));
    ok(-f $sample_tarball, "$sample_tarball copied into position for testing");
    my $sample_checksums = File::Spec->catfile($tdir,
        qw( CPAN authors id S SH SHAY CHECKSUMS ));
    ok(-f $sample_checksums, "$sample_checksums copied into position for testing");

    my $self = CPAN::Cpanorg::Auxiliary->new({ path => $tdir });
    ok(defined $self, "new: returned defined value");
    isa_ok($self, 'CPAN::Cpanorg::Auxiliary');

    ok(-f $self->{path_versions_json},
        "$self->{path_versions_json} located for testing.");

    no warnings 'redefine';
    *CPAN::Cpanorg::Auxiliary::make_api_call = sub {
        my $self = shift;
        my $json_text;
        open my $IN, '<', $self->{path_versions_json}
            or croak "Unable to open $self->{path_versions_json} for reading";
        $json_text = <$IN>;
        while (<$IN>) {
            chomp;
            $json_text .= $_;
        }
        close $IN
            or croak "Unable to close $self->{path_versions_json} after reading";
        return $json_text;
    };
    use warnings;

    chdir $tdir or croak "Unable to change to $tdir for testing";

    $self->fetch_perl_version_data;
    my ( $perl_versions, $perl_testing ) = $self->get_perl_versions_and_testing;
    for ( $perl_versions, $perl_testing ) {
        ok(defined $_, "fetch_perl_version_data() returned defined value");
        ok(ref($_) eq 'ARRAY', "fetch_perl_version_data() returned arrayref");
    }
    my $spv = scalar @{$perl_versions};
    my $spt = scalar @{$perl_testing};
    ok($spv,
        "fetch_perl_version_data() found non-zero number ($spv) of stable releases");
    ok($spt,
        "fetch_perl_version_data() found non-zero number ($spt) of dev or RC releases");

    ok(! defined $self->fetch_perl_version_data,
        "fetch_perl_version_data() returned undefined value when nothing changed");

    $self->add_release_metadata;
    ( $perl_versions, $perl_testing ) = $self->get_perl_versions_and_testing;

    my %statuses = ();
    my $expect = { stable => 3, testing => 15 };
    for my $release (@{$perl_versions}, @{$perl_testing}) {
        $statuses{$release->{status}}++;
    }
    is_deeply(\%statuses, $expect, "Got expected statuses");
    my $sample_release_metadata = $perl_testing->[0];
		for my $k ( qw|
        released
        released_date
        released_time
        status
        type
        url
        version
        version_iota
        version_major
        version_minor
        version_number
    | ) {
        no warnings 'uninitialized';
        ok(length($sample_release_metadata->{$k}),
            "$k: Got non-zero-length string <$sample_release_metadata->{$k}>");
    }
		my $srm_files_metadata = $sample_release_metadata->{files}->[0];
		for my $k ( qw|
        file
        filedir
        filename
        md5
        mtime
        sha1
        sha256
    | ) {
        no warnings 'uninitialized';
        ok(length($srm_files_metadata->{$k}),
            "$k: Got non-zero-length string <$srm_files_metadata->{$k}>");
    }

    my $rv = $self->write_security_files_and_symlinks;
    ok($rv, "write_security_files_and_symlinks() returned true value");

    {
        note("Test creation of security files");
        my @expected_security_files =
            map { File::Spec->catfile(
                '5.0',
                "perl-5.27.11.tar.gz." . $_ . ".txt"
            ) }
            qw( sha1 sha256 md5 );
        for my $security (@expected_security_files) {
            ok(-f $security, "Security file '$security' located");
        }
    }

    {
        note("Test creation of symlinks");

        my ($expected_symlink, $target);

        note("Latest dev release in sample");
        $expected_symlink = File::Spec->catfile(
                '5.0',
                "perl-5.27.11.tar.gz"
        );
        ok(-l $expected_symlink, "Found symlink '$expected_symlink'");
        $target = readlink($expected_symlink);
        chdir $self->{fivedir} or croak "Unable to chdir to $self->{fivedir}";
        ok(-f $target, "Found target of symlink '$expected_symlink': '$target'");
        chdir $self->{srcdir} or croak "Unable to change back to $self->{srcdir}";

        note("A stable release, from 5.0 directory");
        $expected_symlink = File::Spec->catfile(
                '5.0',
                "perl-5.26.0.tar.gz"
        );
        ok(-l $expected_symlink, "Found symlink '$expected_symlink'");
        $target = readlink($expected_symlink);
        chdir $self->{fivedir} or croak "Unable to chdir to $self->{fivedir}";
        ok(-f $target, "Found target of symlink '$expected_symlink': '$target'");
        chdir $self->{srcdir} or croak "Unable to change back to $self->{srcdir}";

        note("A stable release");
        $expected_symlink = File::Spec->catfile("perl-5.26.0.tar.gz");
        $target = readlink($expected_symlink);
        ok(-f $target, "Found target of symlink '$expected_symlink': '$target'");
    }

    $rv = $self->create_latest_only_symlinks;
    ok($rv, "create_latest_only_symlinks() returned true value");

    {
        note("Test creation of 'latest' and 'stable' symlinks");
        chdir $self->{srcdir} or croak "Unable to change back to $self->{srcdir}";
        my ($expected_symlink, $latest_target, $stable_target);

        note("latest");
        $expected_symlink = File::Spec->catfile("latest.tar.gz");
        $latest_target = readlink($expected_symlink);
        ok(-f $latest_target, "Found target of symlink '$expected_symlink': '$latest_target'");

        note("stable");
        $expected_symlink = File::Spec->catfile("stable.tar.gz");
        $stable_target = readlink($expected_symlink);
        ok(-f $stable_target, "Found target of symlink '$expected_symlink': '$stable_target'");
        cmp_ok($latest_target, 'eq', $stable_target,
            "'latest' and 'stable' point to the same release");
    }

    chdir $cwd or croak "Unable to change back to $cwd";
}

done_testing;

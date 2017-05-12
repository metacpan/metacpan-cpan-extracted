# -*- perl -*-

# t/001_new.t

use 5.010;
use Carp;
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use Test::More tests => 16;

BEGIN { use_ok( 'CPAN::Mini::Visit::Simple' ); }

# First, make sure that the constructor has a config_file available even if
# there is no real .minicpanrc available (as would be the case when this
# distribution is tested by CPAN Testers).

{
    my $tdir = tempdir( CLEANUP => 1 );
    my $testing_minicpan_dir = File::Spec->catdir($tdir, 'minicpan');
    make_path($testing_minicpan_dir, { mode => 0711 });
    ok( -d $testing_minicpan_dir, "'minicpan' directory created for testing" );
    my $id_dir = File::Spec->catdir($testing_minicpan_dir, qw( authors id));
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors id' directory created for testing" );

    my $config_file = File::Spec->catfile($tdir, '.minicpanrc');
    open my $CONFIG, '>', $config_file
        or croak "Unable to open $config_file for writing";
    print $CONFIG <<EOF;
local:          $testing_minicpan_dir
remote:         http://www.cpan.org/
exact_mirror:   1
EOF
    close $CONFIG or croak "Unable to close $config_file after writing";
    ok (-f $config_file, "config_file $config_file located for testing");

    local $ENV{CPAN_MINI_CONFIG} = $config_file;

    my $self = CPAN::Mini::Visit::Simple->new();
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');

    $self = CPAN::Mini::Visit::Simple->new({});
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');

    my $real_minicpan = $self->get_minicpan;
    ok( ( -d $real_minicpan ),
        "Top minicpan directory exists: $real_minicpan" );

    my $real_id_dir = $self->get_id_dir;
    ok( ( -d $real_id_dir ),
        "'authors/id/' directory exists: $real_id_dir" );
}

# From this point forward in this file, we're testing failure conditions.

{
    my ($phony_minicpan, $self);
    $phony_minicpan = '/foo/bar';
    eval {
        $self = CPAN::Mini::Visit::Simple->new({
            minicpan => $phony_minicpan,
        });
    };
    like($@, qr/\QDirectory $phony_minicpan not found\E/,
        "Got expected error message for non-existent minicpan directory" );
}

{
    my ($tdir, $id_dir, $self);
    $tdir = tempdir( CLEANUP => 1 );
    $id_dir = File::Spec->catdir($tdir, qw( authors id ));
    eval {
        $self = CPAN::Mini::Visit::Simple->new({
            minicpan => $tdir,
        });
    };
    like($@, qr/\QAbsence of $id_dir implies no valid minicpan\E/,
        "Got expected error message for malformed minicpan repository" );
}

{
    my ($tdir, $id_dir, $self, $author_dir);
    $tdir = tempdir( CLEANUP => 1 );
    $id_dir = File::Spec->catdir($tdir, qw( authors id ));
    make_path($id_dir, { mode => 0711 });
    ok( -d $id_dir, "'authors/id' directory created for testing" );
    $author_dir = File::Spec->catdir($id_dir, qw( A AA AARDVARK ) );
    make_path($author_dir, { mode => 0711 });
    ok( -d $author_dir, "'author's directory created for testing" );

    my @source_list = qw(
        Alpha-Beta-0.01-tar.gz
        Gamma-Delta-0.02-tar.gz
        Epsilon-Zeta-0.03-tar.gz
    );
    foreach my $distro (@source_list) {
        my $fulldistro = File::Spec->catfile($author_dir, $distro);
        open my $FH, '>', $fulldistro
            or croak "Unable to open handle to $distro for writing";
        say $FH q{};
        close $FH or croak "Unable to close handle to $distro after writing";
        ok( ( -f $fulldistro ), "$fulldistro created" );
    }

    $self = CPAN::Mini::Visit::Simple->new({
        minicpan => $tdir,
    });
    isa_ok ($self, 'CPAN::Mini::Visit::Simple');
}

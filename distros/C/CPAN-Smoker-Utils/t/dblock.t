use warnings;
use strict;
use Test::More;
use YAML::XS qw(LoadFile Dump);
use CPAN::Smoker::Utils qw(block_distro);
use File::Spec;
use CPAN;
use CPAN::HandleConfig;
use CPAN::Smoker::Utils::PerlConfig;
use Config;

my $total_tests = 2;
plan tests => $total_tests;

SKIP: {

    skip
"Can only run those tests with cpan client, currently testing with cpanplus, version $ENV{PERL5_CPANPLUS_IS_VERSION}",
        $total_tests
        unless ( not( exists( $ENV{PERL5_CPANPLUS_IS_VERSION} ) ) );

    CPAN::HandleConfig->load;
    my $prefs_dir = $CPAN::Config->{prefs_dir};

    skip "prefs_dir '$prefs_dir' is not available for reading/writing",
        $total_tests
        unless ( -d $prefs_dir && -r $prefs_dir && -w $prefs_dir );

    my $distro_name = 'ARFREITAS/Foo-Bar';
    my %perl_info   = (
        no_useithreads => 'define',
        osname         => 'openbsd',
        archname       => 'Openbsd.amd64-openbsd'
    );
    my $data_ref
        = block_distro( $distro_name, \%perl_info, 'Tests hang smoker' );

    # required to avoid issue with different paths
    delete( $data_ref->{full_path} );
    my $expected = LoadFile(
        File::Spec->catfile( 't', 'distroprefs', 'ARFREITAS.Foo-Bar.yml' ) );
    like( $data_ref->{match}->{distribution},
        qr/^\^ARFREITAS/,
        'the created distroprefs has the expected distro name' );

    # to match the current running OS
    update_per_env($expected);
    my $perl_info = CPAN::Smoker::Utils::PerlConfig->new;
    $data_ref
        = block_distro( $distro_name, $perl_info->dump, 'Tests hang smoker' );
    delete( $data_ref->{full_path} );
    note('Testing with CPAN::Reporter::Smoker::OpenBSD::PerlConfig');
    is_deeply( $data_ref, $expected, 'block_distro works as expected' )
        or diag( explain($data_ref) );
}

sub update_per_env {
    my $expected = shift;
    my $shortcut = $expected->{match}->{perlconfig};
    $shortcut->{osname}   = $Config{osname};
    $shortcut->{archname} = $Config{archname};
    my $attrib_name = 'useithreads';

    if (    ( exists( $Config{$attrib_name} ) )
        and ( defined( $Config{$attrib_name} ) )
        and ( $Config{$attrib_name} eq 'define' ) )
    {
        $shortcut->{$attrib_name} = 'define';
    }

    return 1;
}

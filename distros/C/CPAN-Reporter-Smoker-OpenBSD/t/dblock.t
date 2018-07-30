use warnings;
use strict;
use Test::More;
use YAML::XS qw(LoadFile Dump);
use CPAN::Reporter::Smoker::OpenBSD qw(block_distro);
use File::Spec;
use CPAN;
use CPAN::HandleConfig;

my $total_tests = 3;
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
        useithreads     => 'define',
        osname          => 'openbsd',
        archname        => 'Openbsd.amd64-openbsd'
    );
    my $data_ref =
      block_distro( $distro_name, \%perl_info, 'Tests hang smoker' );
    ok( delete( $data_ref->{full_path} ), 'can remove full_path property' );
    my $expected = LoadFile(
        File::Spec->catfile( 't', 'distroprefs', 'ARFREITAS.Foo-Bar.yml' ) );
    like( $data_ref->{match}->{distribution},
        qr/^\^ARFREITAS/,
        'the created distroprefs has the expected distro name' );
    is_deeply( $data_ref, $expected, 'block_distro works as expected' );
}

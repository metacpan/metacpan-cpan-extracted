use warnings;
use strict;
use Test::More;
use YAML::XS qw(LoadFile Dump);
use CPAN::Reporter::Smoker::OpenBSD qw(block_distro);
use File::Spec;
use CPAN;
use CPAN::HandleConfig;

my $total_tests = 2;
plan tests => $total_tests;

SKIP: {

    skip "Can only run those tests with cpan client, currently testing with cpanplus, version $ENV{PERL5_CPANPLUS_IS_VERSION}",
      $total_tests
      unless (not(exists($ENV{PERL5_CPANPLUS_IS_VERSION})));

    CPAN::HandleConfig->load;
    my $prefs_dir = $CPAN::Config->{prefs_dir};

    skip "prefs_dir '$prefs_dir' is not available for reading/writing",
      $total_tests
      unless ( -d $prefs_dir && -r $prefs_dir && -w $prefs_dir );

    my $data_ref =
      block_distro( 'AWWAIID/Devel-ebug', 'cperl-5.24.3', 'Tests hang smoker' );
    ok( delete( $data_ref->{full_path} ), 'can remove full_path property' );
    my $expected = LoadFile(
        File::Spec->catfile( 't', 'distroprefs', 'AWWAIID.Devel-ebug.yml' ) );

    is_deeply( $data_ref, $expected, 'block_distro works as expected' );
}

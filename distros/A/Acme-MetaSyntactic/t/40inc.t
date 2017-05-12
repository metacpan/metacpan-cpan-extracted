use Test::More tests => 1;
use File::Spec::Functions;
my $dir;
BEGIN { $dir = catdir qw( t lib ); }
use lib $dir;

# look for themes in all @INC
use_ok( 'Acme::MetaSyntactic::test_ams_list' );

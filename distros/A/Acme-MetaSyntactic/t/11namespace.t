use File::Spec::Functions;
my $dir;
BEGIN { $dir = catdir qw( t lib ); }
use lib $dir;
use Test::More tests => 1;
use Acme::MetaSyntactic::test_ams_list;

# check that metaname is not exported into Acme::MetaSyntactic::List
ok(
    !exists $Acme::MetaSyntactic::List::{metaname},
    "metaname not exported to AMS::List"
);

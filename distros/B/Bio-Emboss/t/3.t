# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 3.t'

#########################

# --- if the tests are failing, try to comment out the following line
BEGIN { delete $ENV{PERL_DL_NONLAZY}; };

use Test;
BEGIN { plan tests => 6 };
use Bio::Emboss qw(:all);

ok(1); # If we made it this far, we're ok.

embInitPerl("acdc", ["-auto"]);

my $str = ajStrNew();
ok(UNIVERSAL::isa($str, "Bio::Emboss::Str"));

my $plain = "hello_world.txt";

my $bool = ajStrAssignC($str, $plain);
ok($str->ajStrStr(), $plain);

# --- testing if modified $str object is returned properly to perl
$bool = $str->ajStrSetRes(88);
ok($str->ajStrStr(), $plain);

$str->ajFileNameExtC("seq");
ok($str->ajStrStr(), qr/\.seq$/);

$str->ajStrDel(); undef $str;

ok(1);


# Time-stamp: "2004-12-29 19:48:37 AST"

require 5.004;  # altho test 11 fails before 5.005, it seems

use Array::Autojoin;
use Test;
use strict;
BEGIN { plan tests => 19 }
ok 1;
print "#   Array::Autojoin version: $Array::Autojoin::VERSION\n",
      "#   Perl version $]\n";

my $x = mkarray(4, 5, 6);
my $y = mkarray(0, undef, '');
my $z = mkarray(@$x);

print "#  x: <$x>\n";
print "#  z: <$z>\n";

ok @$x == 3;
ok @$y == 3;
ok @$z == 3;

ok $z eq $x;
ok $z == $x;

ok ref $x;
ok ref $y;
ok ref $z;

if(    $x) { ok 1 } else { ok 0 };
if(not $y) { ok 1 } else { ok 0 };

ok 14 == (10 + $x);
ok 14 == (14 + $y);
ok "4, 5, 6" eq $x;
$x .= '.5';
ok "4, 5, 6.5" eq $x;

ok $z == $x;
push @$x, 7;
ok "4, 5, 6.5, 7" eq $x;

ok $z == $x;

@$x = qw(foo bar BAZ QUUX);
ok $x eq "foo, bar, BAZ, QUUX";

print "#Tests done.\n";
# END

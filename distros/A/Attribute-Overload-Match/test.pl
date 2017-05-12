use strict;
use warnings;
use Attribute::Overload::Match;
use Test::More tests => 6;
no warnings 'redefine';

BEGIN { use_ok('Attribute::Overload::Match'); }
require_ok('Attribute::Overload::Match');

sub new($)               { my $x = $_[0]; bless \$x, __PACKAGE__ }
sub val($)               { ${$_[0]} }
sub eq       : op(==)    { val(shift) == shift }
sub subtract : op(-)     { new val(shift) - shift }
sub mul      : op(*)     { new val(shift) * shift }
sub add      : op(+)     { new val(shift) + shift }
sub div      : op(+)     { new val(shift) / shift }
sub qq       : op("")    { val(shift) }
sub le       : op(<)     { val(shift) < shift }

sub fac      : op(!,1)   { new 1 }
sub fac      : op(!)     { !($_[0] - 1) * $_[0] }

sub fib      : op(~,<2)  { new 1 }
sub fib      : op(~)     { ~( $_[0] - 1) + ~($_[0] - 2) }

my $x = new(5);
ok( $x == 5, 'eq');

my $b = $x - 1;
ok( $b == 4, 'subtract');

$b = !($b);
ok( $b == 24, 'fac');

my $c = ~new(8);
ok( $c == 34, 'fib');

#
# $Id: 02-decycle_deeply.t,v 0.1 2010/08/22 19:58:45 dankogai Exp $
#
use strict;
use warnings;
use Test::More;
use Data::Decycle qw/has_cyclic_ref decycle_deeply recsub $CALLEE/;

plan tests => 14;

my $sref = 'scalar';
ok !has_cyclic_ref($sref), "'$sref' isn't cyclic";
$sref = \$sref;
ok has_cyclic_ref($sref), "'$sref' is cyclic";
{
    no warnings 'uninitialized';
    decycle_deeply($sref);
    ok !has_cyclic_ref($sref), "'$sref' isn't cyclic";
}

my $aref = [0]; 
ok !has_cyclic_ref($aref), "'$aref' isn't cyclic";
$aref->[1] = $aref;
ok has_cyclic_ref($aref), "'$aref' is cyclic";
decycle_deeply($aref);
ok !has_cyclic_ref($aref), "'$aref' isn't cyclic";

my $href = {foo => 0};
ok !has_cyclic_ref($href), "'$href' isn't cyclic";
$href->{cycle} = $href;
ok has_cyclic_ref($href), "'$href' is cyclic";
decycle_deeply($href);
ok !has_cyclic_ref($sref), "'$href' isn't cyclic";

SKIP:{
    skip 'PadWalker not installed', 5 unless Data::Decycle::HAS_PADWALKER;
    my $cref;
    $cref = sub{ $_[0] <= 1 ? 1 : $_[0] * $cref->($_[0] - 1) };
    ok has_cyclic_ref($cref), "'$cref' is cyclic";
    is $cref->(10), 3628800, "($cref)->(10) is 3628800";
    {
	no warnings 'uninitialized';
	decycle_deeply($cref);
	ok !has_cyclic_ref($cref), "'$sref' isn't cyclic";
    }
    $cref = sub{ shift };
    ok !has_cyclic_ref($cref), "'$cref' isn't cyclic";
    $cref = recsub { $_[0] <= 1 ? 1 : $_[0] * $CALLEE->($_[0]-1) };
    ok !has_cyclic_ref($cref), "'$cref' isn't cyclic";
}

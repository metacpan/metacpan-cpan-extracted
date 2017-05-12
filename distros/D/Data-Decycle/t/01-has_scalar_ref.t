#
# $Id: 01-has_scalar_ref.t,v 0.1 2010/08/22 19:58:45 dankogai Exp $
#
use strict;
use warnings;
use Test::More;
use Data::Decycle qw/has_cyclic_ref recsub $CALLEE/;

plan tests => 11;

my $sref = 'scalar';
ok !has_cyclic_ref($sref), "'$sref' isn't cyclic";
$sref = \$sref;
ok has_cyclic_ref($sref), "'$sref' is cyclic";

my $aref = [0]; 
ok !has_cyclic_ref($aref), "'$aref' isn't cyclic";
$aref->[1] = $aref;
ok has_cyclic_ref($aref), "'$aref' is cyclic";

my $href = {foo => 0};
ok !has_cyclic_ref($href), "'$href' isn't cyclic";
$href->{cycle} = $href;
ok has_cyclic_ref($href), "'$href' is cyclic";

bless $aref, 'Dummy';
ok has_cyclic_ref($aref), "'$aref' is cyclic";

bless $href, 'Dummy';
ok has_cyclic_ref($href), "'$href' is cyclic";

SKIP:{
    skip 'PadWalker not installed', 3 unless Data::Decycle::HAS_PADWALKER;
    my $cref;
    $cref = sub{ $_[0] <= 1 ? 1 : $_[0] * $cref->($_[0] - 1) };
    ok has_cyclic_ref($cref), "'$cref' is cyclic";
    $cref = sub{ shift };
    ok !has_cyclic_ref($cref), "'$cref' isn't cyclic";
    $cref = recsub { $_[0] <= 1 ? 1 : $_[0] * $CALLEE->($_[0]-1) };
    ok !has_cyclic_ref($cref), "'$cref' isn't cyclic";
}


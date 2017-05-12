#
# $Id: 04-may_leak.t,v 0.1 2010/08/22 19:58:45 dankogai Exp $
#
use strict;
use warnings;
use Test::More;
use Data::Decycle qw/may_leak weaken_deeply recsub $CALLEE/;

plan tests => 13;

my $sref = 'scalar';
ok !may_leak($sref), "'$sref' may not leak";
$sref = \$sref;
ok may_leak($sref), "'$sref' is leak";
weaken_deeply($sref);
ok !may_leak($sref), "'$sref' may not leak";

my $aref = [0]; 
ok !may_leak($aref), "'$aref' may not leak";
$aref->[1] = $aref;
weaken_deeply($aref);
ok !may_leak($aref), "'$aref' may not leak";

my $href = {foo => 0};
ok !may_leak($href), "'$href' may not leak";
$href->{cycle} = $href;
ok may_leak($href), "'$href' may leak";
weaken_deeply($href);
ok !may_leak($href), "'$href' may not leak";

SKIP:{
    skip 'PadWalker not installed', 5 unless Data::Decycle::HAS_PADWALKER;
    my $cref;
    $cref = sub{ $_[0] <= 1 ? 1 : $_[0] * $cref->($_[0] - 1) };
    ok may_leak($cref), "'$cref' may leak";
    weaken_deeply($cref);
    ok may_leak($cref), "'$cref' may STILL leak";
    is $cref->(10), 3628800, "($cref)->(10) is 3628800";

    $cref = sub{ shift };
    ok !may_leak($cref), "'$cref' may not leak";
    $cref = recsub { $_[0] <= 1 ? 1 : $_[0] * $CALLEE->($_[0]-1) };
    ok !may_leak($cref), "'$cref' may not leak";
}


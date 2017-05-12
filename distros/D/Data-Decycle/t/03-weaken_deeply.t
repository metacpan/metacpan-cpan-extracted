#
# $Id: 03-weaken_deeply.t,v 0.1 2010/08/22 19:58:45 dankogai Exp $
#
use strict;
use warnings;
use Test::More;
use Scalar::Util qw/isweak/;
use Data::Decycle qw/weaken_deeply/;

plan tests => 6;

{
    my $sref;
    $sref = \$sref;
    bless $sref, 'Dummy';
    ok !isweak($sref), "$sref is not a weak reference";
    weaken_deeply($sref);
    ok isweak($sref), "$sref is a weak reference now";
}
{
    my $aref = bless [], 'Dummy';
    $aref->[0] = $aref;
    ok !isweak($aref->[0]), "($aref)->[0] is not a weak reference";
    weaken_deeply($aref);
    ok isweak($aref->[0]), "($aref)->[0] is a weak reference now";
}
{
    my $href = bless {}, 'Dummy';
    $href->{cyclic} = $href;
    ok !isweak($href->{cyclic}), "($href)->{cyclic} is not a weak reference";
    weaken_deeply($href);
    ok isweak($href->{cyclic}), "($href)->{cyclic} is a weak reference now";
}

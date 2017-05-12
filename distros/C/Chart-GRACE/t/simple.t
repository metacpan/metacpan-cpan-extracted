#!/usr/local/bin/perl -w

# Test using simple pipes

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Chart::GRACE;
$loaded = 1;
print "ok 1\n";


@a = (1,4,2,6,5);

$Chart::GRACE::NPIPE = 0;

$xmgr = new Chart::GRACE;
$xmgr->plot(\@a, { SYMBOL => 3, LINECOL => 'red', LINESTYLE => 2, FILL=>0,
SYMSIZE=>1 });

$xmgr->configure(SYMCOL=>'green');

$xmgr->prt('s0 POINT 2,3');


@a = (0.1,0.3,0.1,0.5);
@b = (4,6,3,5);
@c = (2,2,4,1);

$xmgr->set(1);

#$xmgr->prt('@s1 type xydx');

$xmgr->plot(\@b, \@c);

$xmgr->set(0);

print "ok 2\n";

$xmgr->prt("sleep 2");
$xmgr->plot(\@c, \@b, {settype => 'xy', linewid => 3.4});

$xmgr->detach;

print "ok 3\n"



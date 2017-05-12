#!/usr/local/bin/perl -w

# This test is the same as simple.t except that a named pipe is used.

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Chart::GRACE;
$loaded = 1;
print "ok 1\n";


@a = (1,4,2,6,5);

$Chart::GRACE::NPIPE = 1;

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

$xmgr->prt("sleep 1");
$xmgr->plot(\@c, \@b, {settype => 'xy', linewid => 3.4});

$xmgr->detach;
undef $xmgr;


print "ok 3\n";

# Pause since xmgrace complains about the pipe going away if we end
# too early
sleep 2;

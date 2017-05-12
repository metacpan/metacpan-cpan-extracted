#!./perl
$| = 1;
print "1..6\n";
require Audio::Play;
print "ok 1\n";
my $dev = new Audio::Play;
print "not " unless ($dev);
print "ok 2\n";
my $r = 0;
$r = $dev->rate if ($dev);
print "not " unless ($r > 0);
print "ok 3\n";
my $au = Audio::Data->new(rate => $r);
$au->tone(440,0.2);
$au->silence(0.2);
$au->noise(0.2);
$dev->play($au) if $dev;
print "ok 4\n";
$dev->rate(2*$r);
my $nr = $dev->rate;
printf "#wanted %d got %d\n",2*$r,$nr;
print "not " unless ($nr == 2*$r);
print "ok 5\n";

$au = Audio::Data->new(rate => 2*$r);
$au->tone(440,0.2);
$au->silence(0.2);
$au->noise(0.2);

$dev->play($au) if $dev;
print "ok 6\n";


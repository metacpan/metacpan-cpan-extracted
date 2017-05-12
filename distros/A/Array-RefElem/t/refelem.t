print "1..5\n";

use strict;
use Array::RefElem qw(av_store av_push hv_store);

my $a = "a";
my @a = (1, 2, 3, 4);

av_store(@a, 1, $a);
av_push(@a, $a);

print "not " unless "@a" eq "1 a 3 4 a";
print "ok 1\n";

$a = 2;
print "not " unless "@a" eq "1 2 3 4 2";
print "ok 2\n";

$a[1] = "z";
print "not " unless $a[4] eq "z";
print "ok 3\n";

my %h;
hv_store(%h, "foo", $a);

$h{foo} = "bar";
print "not " unless $a eq "bar";
print "ok 4\n";

$a[2] = [3];
av_store(@a, 2, $a[2][0]);
print "not " unless $a[2] == 3;
print "ok 5\n";

if (shift) {
   require Devel::Peek;
   Devel::Peek::Dump($a);
   Devel::Peek::Dump(\@a);
   Devel::Peek::Dump(\%h);
}


BEGIN { print "1..1\n"; print "ok 1\n"; exit }

use Data::Dump qw(dump);

$a = 42;
bless \$a, "Foo";

my $d = dump($a);

print "$d\n";
print "not " unless $d eq q(do {
  my $a = 42;
  bless \$a, "Foo";
  $a;
});
print "ok 1\n";

$d = dump(\$a);
print "$d\n";
print "not " unless $d eq q(bless(do{\\(my $o = 42)}, "Foo"));
print "ok 2\n";

$d = dump(\\$a);
print "$d\n";
print "not " unless $d eq q(\\bless(do{\\(my $o = 42)}, "Foo"));
print "ok 3\n";

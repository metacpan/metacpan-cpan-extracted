BEGIN { $0 = "test.pl";  print "1..2\n";}
use Attribute::Persistent;
BEGIN { print "ok 1\n"; }
my %foo : persistent;
$foo{test} = 1;
print "ok 2\n";



BEGIN { $0 = "test.pl";  print "1..1\n";}
use Attribute::Persistent;
my %foo : persistent;
print "ok 1\n" if $foo{test} == 1;
delete $foo{test};


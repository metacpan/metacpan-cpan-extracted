use Acme::Goto::Line;
print "1..1\n";

my $i = 7;
goto($i);
print "not ok 1\n";
print "ok 1\n";
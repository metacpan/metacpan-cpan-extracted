


use Acme::Goto::Line ;


print "1..4\n";

goto(15);
print "ok 2 # Line: " . __LINE__ . "\n";
goto(25);



print "ok 1 # Line: " . __LINE__ . "\n";
goto(10);



print "ok 4 # Line: " . __LINE__ . "\n";
exit;
sub bar {
    goto(20);
}
print "ok 3 # Line: " . __LINE__ . "\n";
bar();
print "not ok 3 # Line: " . __LINE__ . "\n";



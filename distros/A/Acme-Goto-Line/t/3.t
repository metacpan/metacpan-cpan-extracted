

use Acme::Goto::Line;
print "1..4\n";
Acme::Goto::Line::goto(8);
print "not ok 1 # Line: " . __LINE__ . "\n";
for(1) {
    print "ok 1 # Line: " . __LINE__ . "\n";
    Acme::Goto::Line::goto(12);
}
print "not ok 2 # Line: " . __LINE__ . "\n";
print "ok 2 # Line: " . __LINE__ . "\n";



for(1) {
   Acme::Goto::Line::goto(20);
   print "not ok 3 # Line: " . __LINE__ . "\n";
}
print "ok 3 # Line: " . __LINE__ . "\n";

Acme::Goto::Line::goto(25);
print "not ok 4 # Line: " . __LINE__ . "\n";
for(1) {
    print "ok 4 # Line: " . __LINE__ . "\n";
}

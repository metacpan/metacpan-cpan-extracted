use AppReg;
use Example1; 
use PNDI;

my $DbObj = Example1->find('Foo1');
my $PID   = $$;

print $DbObj, "\n";

print "getBar()\n";
print "> ", $DbObj->getBar(); 
print "\n";

print "setBar('Bar_$PID')\n"; 
print "> ", $DbObj->setBar("Bar_$PID");
print "\n"; 

print "getBar()\n";
print "> ", $DbObj->getBar(); 
print "\n";

$DbObj->update(); 

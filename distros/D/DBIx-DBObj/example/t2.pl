use AppReg;
use Example1; 
use PNDI;

my $DbObj = Example1->find('Foo1');

print $DbObj, "\n"; 
print $DbObj->getFoo(), "\n"; 
print $DbObj->getBar(), "\n"; 
print $DbObj->getBaz(), "\n"; 



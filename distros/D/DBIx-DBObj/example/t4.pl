use AppReg;
use Example1; 
use PNDI;

my $DbObjs = Example1->search({Foo => 'Foo1'});
my $DbObj  = $DbObjs->[0]; 

print $DbObj, "\n"; 
print $DbObj->getFoo(), "\n"; 
print $DbObj->getBar(), "\n"; 
print $DbObj->getBaz(), "\n"; 



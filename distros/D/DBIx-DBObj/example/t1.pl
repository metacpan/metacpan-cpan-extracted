use AppReg; 
use Example1; 
use PNDI;

my $DbObj = Example1->create({
              'Foo' => 'Foo1',
              'Bar' => join('-','Bar',time()),
              'Baz' => join('-','Bar',time()), 1});

print $DbObj, "\n"; 
print $DbObj->getFoo(), "\n"; 
print $DbObj->getBar(), "\n"; 
print $DbObj->getBaz(), "\n"; 



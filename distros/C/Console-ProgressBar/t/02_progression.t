use strict;
use Test::More 'no_plan';

use Console::ProgressBar;

my $currentValue;
my $p = Console::ProgressBar->new('Title',100);

for(my $i=1;$i<=50;$i++) {
    $p->next();
}

$currentValue = $p->_calculateCurrentValue();
is($currentValue,50,'Completion level is 50%');
is($p->_getGraphicBars($currentValue),'##########','Graphic bar contains 10 characters');

for(my $i=1;$i<=50;$i++) {
    $p->next();
}

$currentValue = $p->_calculateCurrentValue();
is($currentValue,100,'Completion level is 100%');
is($p->_getGraphicBars($currentValue),'####################','Graphic bar contains 20 characters');

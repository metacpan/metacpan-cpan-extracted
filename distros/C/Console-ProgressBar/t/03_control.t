use strict;
use Test::More 'no_plan';

use Console::ProgressBar;

my $currentValue;
my $p = Console::ProgressBar->new('Title',100);

$p->setIndex(50);

$currentValue = $p->_calculateCurrentValue();
is($currentValue,50,'Completion level is 50%');
is($p->_getGraphicBars($currentValue),'##########','Graphic bar contains 10 characters');

$p->reset();
$currentValue = $p->_calculateCurrentValue();
is($currentValue,0,'Completion level is 0%');
is($p->_getGraphicBars($currentValue),'','Graphic bar is empty');

$p->setIndex(100);
for(my $i=1;$i <= 40;$i++) {
    $p->back();
}
$currentValue = $p->_calculateCurrentValue();
is($currentValue,60,'Completion level is 60%');
is($p->_getGraphicBars($currentValue),'############','Graphic bar contains 12 characters');

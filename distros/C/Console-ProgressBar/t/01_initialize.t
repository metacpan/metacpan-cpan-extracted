use strict;
use Test::More 'no_plan';

use Console::ProgressBar;

my $p = Console::ProgressBar->new('Title',20);

is($p->getIndex(),0,"Index value equals to 0");

my $currentValue = $p->_calculateCurrentValue();
is($currentValue,0,'Completion level is 0%');
is($p->_getGraphicBars($currentValue),'','Graphic bar is empty');

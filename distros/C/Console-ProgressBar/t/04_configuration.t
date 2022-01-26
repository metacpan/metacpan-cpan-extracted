use strict;
use Test::More 'no_plan';

use Console::ProgressBar;

my $p = Console::ProgressBar->new('Title',100,{
    length => 40,
    segment => '=',
    titleMaxSize => 15
});

$p->setTitle('A new title');
$p->setIndex(50);
is($p->_getGraphicBars($p->_calculateCurrentValue()),'====================',"Graphic bar contains 20 characters and the segment is '='");


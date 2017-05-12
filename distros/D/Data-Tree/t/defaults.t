use Test::More qw( no_plan );
use Data::Tree;

my $T = Data::Tree::->new();

is($T->set('NodeOne',1),1,'Set NodeOne');
is($T->set('NodeZero',0),0,'Set NodeZero');
is($T->set('NodeUndef',undef),undef,'Set NodeUndef');

is($T->get('NodeOne'),1,'Got 1 from NodeOne');
is($T->get('NodeZero'),0,'Got 0 from NodeZero');
is($T->get('NodeUndef'),undef,'Got undef from NodeUndef');

is($T->get('NodeOne', { Default => 2, }),1,'Got 1 from NodeOne w/ default 2');
is($T->get('NodeZero', { Default => 2, }),0,'Got 0 from NodeZero w/ default 2');
is($T->get('NodeUndef', { Default => 2, }),undef,'Got undef from NodeUndef w/ default 2');
is($T->get('NodeUnknown', { Default => 2, }),2,'Got 2 from NodeUnknown w/ default 2' );

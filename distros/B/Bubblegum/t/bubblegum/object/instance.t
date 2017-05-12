use Bubblegum::Object::Instance;
use Test::More;

ok ! main->isa('Moo::Object'), 'class not an object';

can_ok 'Bubblegum::Object::Instance', 'new';
can_ok 'Bubblegum::Object::Instance', 'data';

done_testing;

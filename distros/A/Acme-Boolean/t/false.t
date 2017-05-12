use Acme::Boolean;
use Test::More;

plan tests => 8;

ok !untrue;
ok !wrong;
ok !incorrect;
ok !errorneous;
ok !fallacious;
ok !untruthful;
ok !nah;
ok !Acme::Boolean::no;

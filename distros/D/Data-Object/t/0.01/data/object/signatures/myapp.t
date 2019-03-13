use lib 't/0.01/lib';

use Test::More;

use Data::Object::Config::Signatures qw(MyApp::Types);
use Data::Object::Export qw(deduce);

fun greeting (AllCaps $name) {
  return "hello, $name";
}

fun meeting (NumberObj :$epoch = deduce $$) {
  return "our meeting is at $epoch";
}

is greeting(deduce('MARTIAN')), 'hello, MARTIAN';
ok !eval { greeting(deduce('martian')) };
ok $@;

is meeting(epoch => deduce $$), 'our meeting is at ' . $$;
is meeting(epocj => deduce $$), 'our meeting is at ' . $$;

ok 1 and done_testing;

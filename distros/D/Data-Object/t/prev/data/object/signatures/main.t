use Test::More;

use Data::Object::Signatures;
use Data::Object qw(deduce);

fun greeting (StrObj $name) {
    return "hello, $name";
}

fun meeting (NumObj :$epoch = deduce $$) {
    return "our meeting is at $epoch";
}

is greeting(deduce('martian')), 'hello, martian';
ok ! eval { greeting('martian') };
ok $@;

is meeting(epoch => deduce($$)), 'our meeting is at ' . $$;
is meeting(epocj => deduce($$)), 'our meeting is at ' . $$;

ok 1 and done_testing;

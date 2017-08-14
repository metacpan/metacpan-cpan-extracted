use Test::More tests => 2;
use parent 'CAIXS';

$SIG{__WARN__} = sub {ok 1};

__PACKAGE__->mk_class_accessors('foo');
__PACKAGE__->mk_class_accessors('bar');

is(__PACKAGE__->foo(42), 42);

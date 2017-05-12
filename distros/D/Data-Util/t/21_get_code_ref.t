#!perl -w
use strict;
use Test::More tests => 26;
use Test::Exception;

use Data::Util qw(:all);

sub stub;
sub stub2;
sub stub_with_attr :method;
sub stub_with_proto ();

use constant CONST => 42;

is get_code_ref(__PACKAGE__, 'ok'), \&ok, 'get_code_ref';
is get_code_ref(__PACKAGE__, 'foobar'), undef;

is ref(get_code_ref __PACKAGE__, 'stub'),            'CODE';
is ref(get_code_ref __PACKAGE__, 'stub_with_attr'),  'CODE';
is ref(get_code_ref __PACKAGE__, 'stub_with_proto'), 'CODE';
is ref(get_code_ref __PACKAGE__, 'CONST'),           'CODE';

is eval q{CONST}, 42;

uninstall_subroutine __PACKAGE__, qw(stub stub2 stub_with_attr stub_with_proto);

is get_code_ref(__PACKAGE__, 'stub'), undef;
is get_code_ref(__PACKAGE__, 'stub2'), undef;
is get_code_ref(__PACKAGE__, 'stub_with_attr'), undef;
is get_code_ref(__PACKAGE__, 'stub_with_proto'), undef;

is get_code_ref('FooBar', 'foo'), undef;
is get_code_ref(42,       'foo'), undef;

ok !exists $main::{"Nowhere::"};
ok !get_code_ref("Nowhere", "foo");
ok !exists $main::{"Nowhere::"}, 'not vivify a package';

ok !exists $main::{"nothing"};
ok !get_code_ref("main", "nothing");
ok !exists $main::{"nothing"}, 'not vivify a symbol';

ok !get_code_ref('FooBar', 'foo');
ok  get_code_ref('FooBar', 'foo', -create), '-create';
ok  get_code_ref('FooBar', 'foo'), '... created';

eval q{FooBar::foo()};
like $@, qr/Undefined subroutine \&FooBar::foo/, 'call a created stub';

dies_ok{
	get_code_ref();
};
dies_ok{
	get_code_ref undef, 'foo';
};
dies_ok{
	get_code_ref __PACKAGE__, undef;
};

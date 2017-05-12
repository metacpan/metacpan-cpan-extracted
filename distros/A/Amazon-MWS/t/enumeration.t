use warnings;
use strict;

use Test::More tests => 9;

BEGIN {
    package TestEnum;

    use base 'Amazon::MWS::Enumeration';
    TestEnum->define(qw/
        Foo
        Bar
        Baz
    /);
} 

package indie;
use Test::More;
BEGIN { TestEnum->import('Foo') }

my $thing = Foo;

is($thing, 'Foo');
is(ref $thing, 'TestEnum');
ok(!indie->can('Bar'));

package all;
use Test::More;
BEGIN { TestEnum->import(':all') }

is(Foo, 'Foo');
is(Bar, 'Bar');
is(Baz, 'Baz');

package asClass;
use Test::More;

is(TestEnum->Foo, 'Foo');
is(TestEnum->Bar, 'Bar');
is(TestEnum->Baz, 'Baz');

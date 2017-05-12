#!perl -w

# $Id: base.t 3872 2008-05-09 19:36:23Z david $

use strict;
use Test::More tests => 99;

BEGIN { use_ok('Class::Delegator') }

FOO: {
    package MyTest::Foo;
    sub new { bless {} }
    sub bar {
        my $self = shift;
        return $self->{bar} unless @_;
        $self->{bar} = shift;
    };
    sub try {
        my $self = shift;
        return $self->{try} unless @_;
        $self->{try} = shift;
    };
}

can_ok 'MyTest::Foo' => 'new';
can_ok 'MyTest::Foo' => 'bar';
can_ok 'MyTest::Foo' => 'try';

SIMPLE: {
    package MyTest::Simple;
    sub new { bless { foo => MyTest::Foo->new } }
    use Class::Delegator
      send => 'bar',
      to   => '{foo}',
    ;
}

can_ok 'MyTest::Simple' => 'bar';
ok my $d = MyTest::Simple->new, "Construct new simple object";
is $d->bar, $d->{foo}->bar, "Make sure the simple values are the same";
ok $d->bar('hello'), "Set the value via the simple delegate";
is $d->bar, 'hello', "Make sure that the simple attribute was set";
is $d->{foo}->bar, 'hello', "And that it is in the simple contained object";

TWOSIMPLE: {
    package MyTest::TwoSimple;
    sub new { bless { foo => MyTest::Foo->new, foo2 => MyTest::Foo->new } }
    use Class::Delegator
      send => 'bar',
      to   => '{foo}',

      send => 'try',
      to   => '{foo2}',
    ;
}

can_ok 'MyTest::TwoSimple' => 'bar';
can_ok 'MyTest::TwoSimple' => 'try';
ok $d = MyTest::TwoSimple->new, "Construct new two simple object";
is $d->bar, $d->{foo}->bar, "Make sure the bar simple values are the same";
ok $d->bar('hello'), "Set the value via the bar simple delegate";
is $d->bar, 'hello', "Make sure that the bar simple attribute was set";
is $d->{foo}->bar, 'hello', "And that it is in the bar simple contained object";
isnt $d->bar, $d->try, "Make sure that the two values are different";
is $d->try, $d->{foo2}->try, "Make sure the try simple values are the same";
ok $d->try('fee'), "Set the value via the try simple delegate";
is $d->try, 'fee', "Make sure that the try simple attribute was set";
is $d->{foo2}->try, 'fee', "And that it is in the try simple contained object";
isnt $d->bar, $d->try, "Make sure that the two values are still different";

AS: {
    package MyTest::As;
    sub new { bless { foo => MyTest::Foo->new } }
    use Class::Delegator
      send => 'yow',
      to   => '{foo}',
      as   => 'bar',
    ;
}

ok ! MyTest::As->can('bar'), "MyTest::As cannot 'bar'";
can_ok 'MyTest::As' => 'yow';
ok $d = MyTest::As->new, "Construct new as object";
is $d->yow, $d->{foo}->bar, "Make sure the as values are the same";
ok $d->yow('hello'), "Set the as value via the delegate";
is $d->yow, 'hello', "Make sure that the as attribute was set";
is $d->{foo}->bar, 'hello', "And that it is in the as contained object";

METHOD: {
    package MyTest::Method;
    sub new { bless { foo => MyTest::Foo->new } }
    sub foo { shift->{foo} }
    use Class::Delegator
      send => 'bar',
      to   => 'foo',
    ;
}

can_ok 'MyTest::Method' => 'bar';
ok $d = MyTest::Method->new, "Construct new meth object";
is $d->bar, $d->foo->bar, "Make sure the meth values are the same";
ok $d->bar('hello'), "Set the value via the meth delegate";
is $d->bar, 'hello', "Make sure that the meth attribute was set";
is $d->foo->bar, 'hello', "And that it is in the contained object";

ARRAY: {
    package MyTest::Array;
    sub new { bless [ MyTest::Foo->new ] }
    use Class::Delegator
      send => 'bar',
      to   => '[0]',
    ;
}

can_ok 'MyTest::Array' => 'bar';
ok $d = MyTest::Array->new, "Construct new array object";
is $d->bar, $d->[0]->bar, "Make sure the array values are the same";
ok $d->bar('hello'), "Set the value via the array delegate";
is $d->bar, 'hello', "Make sure that the array attribute was set";
is $d->[0]->bar, 'hello', "And that it is in the contained object";

MULTI: {
    package MyTest::Multi;
    sub new { bless { foo => MyTest::Foo->new } }
    use Class::Delegator
      send => [qw(bar try)],
      to   => '{foo}',
    ;
}

can_ok 'MyTest::Multi' => 'bar';
can_ok 'MyTest::Multi' => 'try';
ok $d = MyTest::Multi->new, "Construct new multi object";
is $d->bar, $d->{foo}->bar, "Make sure the bar values are the same";
ok $d->bar('hello'), "Set the value via the bar delegate";
is $d->bar, 'hello', "Make sure that the bar attribute was set";
is $d->{foo}->bar, 'hello', "And that it is in the foo contained object";
is $d->try, $d->{foo}->try, "Make sure the try values are the same";
ok $d->try('hello'), "Set the value via the try delegate";
is $d->try, 'hello', "Make sure that the try attribute was set";
is $d->{foo}->try, 'hello', "And that it is in the foo contained object";

MULTIAS: {
    package MyTest::MultiAs;
    sub new { bless { foo => MyTest::Foo->new } }
    use Class::Delegator
      send => [qw(rab yrt)],
      to   => '{foo}',
      as   => [qw(bar try)],
    ;
}

can_ok 'MyTest::MultiAs' => 'rab';
can_ok 'MyTest::MultiAs' => 'yrt';
ok $d = MyTest::MultiAs->new, "Construct new multi object";
is $d->rab, $d->{foo}->bar, "Make sure the rab values are the same";
ok $d->rab('hello'), "Set the value via the rab delegate";
is $d->rab, 'hello', "Make sure that the rab attribute was set";
is $d->{foo}->bar, 'hello', "And that it is in the foo contained object";
is $d->yrt, $d->{foo}->try, "Make sure the yrt values are the same";
ok $d->yrt('hello'), "Set the value via the yrt delegate";
is $d->yrt, 'hello', "Make sure that the yrt attribute was set";
is $d->{foo}->try, 'hello', "And that it is in the foo contained object";

MULTITO: {
    package MyTest::MultiTo;
    sub new { bless { foo => MyTest::Foo->new, bat => MyTest::Foo->new } }
    use Class::Delegator
      send => 'bar',
      to   => ['{foo}', '{bat}'],
    ;
}

can_ok 'MyTest::MultiTo' => 'bar';
ok $d = MyTest::MultiTo->new, "Construct new MultiTo object";
is $d->{foo}->bar, undef, "Check that foo's bar is undef";
is $d->{bat}->bar, undef, "Check that bat's bar is undef";
ok $d->bar('yo'), "Set bar_try to 'yo'";
is $d->{foo}->bar, 'yo', "Check that foo's bar is now 'yo'";
is $d->{bat}->bar, 'yo', "Check that bat's bar is now 'yow'";

# Try getting the results.
ok $d = MyTest::MultiTo->new, "Construct another MultiTo object";
is_deeply [$d->bar(1)], [[1], [1]], "Check return array";
is_deeply scalar $d->bar(1), [1, 1], "Check return arrayref";

MULTITOAS: {
    package MyTest::MultiToAs;
    sub new { bless { foo => MyTest::Foo->new, bat => MyTest::Foo->new } }
    use Class::Delegator
      send => 'bar_try',
      to   => ['{foo}', '{bat}'],
      as   => [qw(bar try)],
    ;
}

can_ok 'MyTest::MultiToAs' => 'bar_try';
ok $d = MyTest::MultiToAs->new, "Construct new MultiToAs object";
is $d->{foo}->bar, undef, "Check that foo's bar is undef";
is $d->{foo}->try, undef, "Check that foo's try is undef";
is $d->{bat}->bar, undef, "Check that bat's bar is undef";
is $d->{bat}->try, undef, "Check that bat's try is undef";
ok $d->bar_try('yo'), "Set bar_try to 'yo'";
is $d->{foo}->bar, 'yo', "Check that foo's bar is now 'yo'";
is $d->{foo}->try, undef, "Check that foo's try is still undef";
is $d->{bat}->bar, undef, "Check that bat's bar is still undef";
is $d->{bat}->try, 'yo', "Check that bat's try is now 'yow'";


ERRORS: {
    package MyTest::Errors;
    use Test::More;
    sub new { bless {} }
    sub try {}

    eval { Class::Delegator->import(foo => 'bar') };
    ok my $err = $@, "Catch 'missing send' exception";
    like $err, qr/Expected "send => <method spec>" but found "foo => bar"/,
      "Caught correct 'missing send' exception";

    eval { Class::Delegator->import(send => 'foo', foo => 'bar') };
    ok $err = $@, "Catch 'missing to' exception";
    like $err, qr/Expected "to => <attribute spec>" but found "foo => bar"/,
      "Caught correct 'missing to' exception";

    eval { Class::Delegator->import(send => [], to => []) };
    ok $err = $@, "Catch 'double array' exception";
    like $err, qr/Cannot specify both "send" and "to" as arrays/,
      "Caught correct 'double array' exception";

    eval { Class::Delegator->import(send => 'foo', to => [1], as => []) };
    ok $err = $@, "Catch 'different length' exception";
    like $err, qr/Arrays specified for "to" and "as" must be the same length/,
      "Caught correct 'different length' exception";

    eval { Class::Delegator->import(send => 'foo', to => [1], as => 1) };
    ok $err = $@, "Catch 'scalar as' exception";
    like $err, qr/Cannot specify "as" as a scalar if "to" is an array/,
      "Caught correct 'scalar as' exception";
}

LINENOS: {
    package MyTest::LineNos;
    use Test::More;
    sub new { bless {} }
    sub try { die 'Ow' }

# Fake out line numbering so that we can just use one in the test.
#line 248 t/base.t
    use Class::Delegator
      send => 'hey', # Line 251, error should be from here.
      to   => 'try'
    ;
    # Line 253, sometimes error is here. No idea why.
}

ok my $try = MyTest::LineNos->new, 'Create new LineNos object';
use Carp;
local $SIG{__DIE__} = \&confess;
eval { $try->hey };
ok my $err = $@, 'Should Catch exception';
my $fn = 't/base.t';
like $err, qr/called (?:at\s+$fn|$fn\s+at)\s+line/,
    'The exception should have this file name in it';
like $err, qr/MyTest::LineNos::hey/,
    'The exception should have the name of the delegating method';

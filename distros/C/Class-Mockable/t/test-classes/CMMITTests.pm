package CMMITTests;

use strict;
use warnings;

use constant CMMIT => qw(Class::Mock::Method::InterfaceTester);

use base qw(CMTests::TestClass);

use CMMITTestClass;
use CMMITTestClass::Subclass;

# very similar pre-amble to class-mock-generic-interfacetester.t
# how about some Test::Class and inheritance?

use Config;
use Test::More;
use Scalar::Util qw(blessed);
use Capture::Tiny qw(capture);
use Class::Mock::Method::InterfaceTester;

# mock _ok in C::M::M::IT
sub _setup_mock :Test(setup) {
    Class::Mock::Method::InterfaceTester->_ok(sub {
        my($result, $message) = @_;
        return ($result ? '' : 'not ')."ok 94 $message";
    });
}

sub default_ok :Tests(1) {
    my $perl = $Config{perlpath};

    my $result;
    {
      local $ENV{PERL5LIB} = join($Config{path_sep}, @INC);
      $result = (capture {
        system(
            $perl, qw( -MClass::Mock::Method::InterfaceTester -e ),
            " Class::Mock::Method::InterfaceTester->new([
                { input => ['wobble'], output => 'jelly' }
              ]) "
        )
      })[0];
    }
    ok($result =~ /^not ok.*didn't run all tests/, "normal 'ok' works")
        || diag($result);
}

sub _check_result {
    my($expected, $got, $message) = @_;
    $expected =~ s/%s/.*?/g;
    $expected = qr/$expected/s;
    like($got, $expected, $message);
}

sub wrong_args_structure :Tests(1) {
    CMMITTestClass->_reset_test_method();
    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );

    _check_result(
        CMMIT->WRONG_ARGS_W_EXPECTED,
        CMMITTestClass->_test_method('bar'),
        "detects wrong args to method"
    );
}

sub wrong_args_subref :Tests(2) {
    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => sub { $_[0] eq 'foo' } , output => 'foo' },
            { input => sub { $_[0] eq 'foo' } , output => 'foo' },
        ])
    );

    ok(CMMITTestClass->_test_method('foo') eq 'foo', "correct method call gets right result back (checking with a subref)");
    _check_result(
        CMMIT->WRONG_ARGS,
        CMMITTestClass->_test_method('bar'),
        "detects wrong args to method (checking with a subref)"
    );
}

sub correct_method_call_gets_correct_results :Tests(5) {
    CMMITTestClass->_reset_test_method();
    ok(CMMITTestClass->_test_method('foo') eq "called test_method on CMMITTestClass with [foo]\n",
        "calling a method after _reset()ing works"
    );

    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
            { input => ['foo'], output => \sub { 'foo' } },
            { input => ['foo'], output => sub { 'foo' } },
            { input => ['foo'], output => \{ eleven => 11 } },
        ]),
    );

    ok(
        CMMITTestClass->_test_method('foo') eq 'foo',
        "correct method call gets right result back"
    );
    ok(
        CMMITTestClass->_test_method('foo') eq 'foo',
        "correct method call gets right result back by executing a code-ref"
    );
    ok(
        CMMITTestClass->_test_method('foo')->() eq 'foo',
        "can return a code-ref"
    );
    is_deeply(
        CMMITTestClass->_test_method('foo'),
        \{ eleven => 11 },
        "can return random other refs"
    );
}

sub run_out_of_tests :Tests(1) {
    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );

    CMMITTestClass->_test_method('foo'); # eat the first test
    _check_result(
        CMMIT->RUN_OUT,
        CMMITTestClass->_test_method('bar'),
        "run out of tests"
    );
}

sub didnt_run_all_tests :Tests(1) {
    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );
    # the DESTROY spits out a test, so we need to do this
    # because we can't capture its return value
    Class::Mock::Method::InterfaceTester->_ok(sub { Test::More::ok(!shift(), shift()); });

    CMMITTestClass->_reset_test_method();
}

sub inheritance :Tests(3) {
    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { input => ['foo'], output => 'foo' },
        ])
    );
    ok(CMMITTestClass::Subclass->test_method('foo') eq "called test_method on CMMITTestClass::Subclass with [foo]\n",
        "yup, subclass is good (sanity check)");
    ok(CMMITTestClass::Subclass->_test_method('foo') eq 'foo', "called mock on subclass OK");
    _check_result(
        CMMIT->RUN_OUT,
        CMMITTestClass::Subclass->_test_method('foo'),
        "run out of tests (using inheritance)"
    );
}

sub invocant_class_and_object :Tests(1) {
    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { invocant_class => 'CMMITTestClass', invocant_object => 'CMMITTestClass', input => ['foo'], output => 'foo' },
        ])
    );
    _check_result(
        CMMIT->BOTH_INVOCANTS,
        CMMITTestClass->_test_method('foo'),
        "can't have both of _invocant_{class,object}"
    );
}

sub invocant_class :Tests(5) {
    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { invocant_class => 'CMMITTestClass',           input => ['foo'], output => 'foo' },
            { invocant_class => 'CMMITTestClass',           input => ['foo'], output => 'foo' },
            { invocant_class => 'CMMITTestClass',           input => ['foo'], output => 'foo' },
            { invocant_class => 'CMMITTestClass::Subclass', input => ['foo'], output => 'foo' },
            { invocant_class => 'CMMITTestClass::Subclass', input => ['foo'], output => 'foo' },
        ])
    );

    _check_result(
        CMMIT->EXP_CLASS_GOT_OBJECT,
        bless({}, 'CMMITTestClass')->_test_method('foo'),
        "called method on object, not class"
    );

    ok(CMMITTestClass->_test_method('foo') eq 'foo', "called on right class");
    _check_result(
        CMMIT->WRONG_CLASS,
        CMMITTestClass::Subclass->_test_method('foo'),
        "called on wrong class, via inheritance"
    );
    _check_result(
        CMMIT->WRONG_CLASS,
        CMMITTestClass->_test_method('foo'),
        "called on wrong class"
    );
    ok(CMMITTestClass::Subclass->_test_method('foo') eq 'foo', "called on right class via inheritance");
}

# re-factor these two
sub invocant_object_string :Tests(5) {
    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { invocant_object => 'CMMITTestClass',           input => ['foo'], output => 'foo' },
            { invocant_object => 'CMMITTestClass',           input => ['foo'], output => 'foo' },
            { invocant_object => 'CMMITTestClass',           input => ['foo'], output => 'foo' },
            { invocant_object => 'CMMITTestClass::Subclass', input => ['foo'], output => 'foo' },
            { invocant_object => 'CMMITTestClass::Subclass', input => ['foo'], output => 'foo' },
        ])
    );

    _check_result(
        CMMIT->EXP_OBJECT_GOT_CLASS,
        CMMITTestClass->_test_method('foo'),
        "called method on class, not object"
    );

    ok(bless({}, 'CMMITTestClass')->_test_method('foo') eq 'foo', "called on object of right class");
    _check_result(
        CMMIT->WRONG_OBJECT,
        bless({}, 'CMMITTestClass::Subclass')->_test_method('foo'),
        "called method on object of wrong class, via inheritance"
    );
    _check_result(
        CMMIT->WRONG_OBJECT,
        bless({}, 'CMMITTestClass')->_test_method('foo'),
        "called method on object of wrong class"
    );
    ok(bless({}, 'CMMITTestClass::Subclass')->_test_method('foo') eq 'foo', "called on object of right class via inheritance");
}

sub invocant_object_subref :Tests(4) {
    CMMITTestClass->_set_test_method(
        Class::Mock::Method::InterfaceTester->new([
            { invocant_object => sub { blessed($_[0]) eq 'CMMITTestClass' },           input => ['foo'], output => 'foo' },
            { invocant_object => sub { blessed($_[0]) eq 'CMMITTestClass' },           input => ['foo'], output => 'foo' },
            { invocant_object => sub { blessed($_[0]) eq 'CMMITTestClass::Subclass' }, input => ['foo'], output => 'foo' },
            { invocant_object => sub { blessed($_[0]) eq 'CMMITTestClass::Subclass' }, input => ['foo'], output => 'foo' },
        ])
    );

    ok(bless({}, 'CMMITTestClass')->_test_method('foo') eq 'foo', "called on object that matches sub-ref");
    _check_result(
        CMMIT->WRONG_OBJECT_SUBREF,
        bless({}, 'CMMITTestClass::Subclass')->_test_method('foo'),
        "called on object that doesn't match sub-ref, via inheritance"
    );
    _check_result(
        CMMIT->WRONG_OBJECT_SUBREF,
        bless({}, 'CMMITTestClass')->_test_method('foo'),
        "called on object that doesn't match sub-ref"
    );
    ok(bless({}, 'CMMITTestClass::Subclass')->_test_method('foo') eq 'foo', "called on object that matches sub-ref, via inheritance");
}

1;

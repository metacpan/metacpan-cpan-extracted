package Class::Mock::Generic::InterfaceTester;

use strict;
use warnings;

our $VERSION = '1.2001';

use vars qw($AUTOLOAD);

use Test::More ();
use Data::Compare;
use Scalar::Util;
use Data::Dumper;
local $Data::Dumper::Indent = 1;

use Class::Mockable
    _ok => sub { Test::More::ok($_[0], @_[1..$#_]) };

=head1 NAME

Class::Mock::Generic::InterfaceTester

=head1 DESCRIPTION

A mock object for testing that you call other code correctly

=head1 SYNOPSIS

In the code under test:

    package My::Module;

    use Class::Mockable
        _storage_class => 'MyApp::Storage';

and in the tests:

    My::Module->_storage_class(
        Class::Mock::Generic::InterfaceTester->new([
            {
                method => 'fetch',
                input  => [customer_id => 94],
                output => ...
            },
            {
                method => 'update',
                input  => [status => 'fired', reason => 'non-payment'],
                output => 1,
            },
            ...
        ]);
    );

or, more simply:

    my $interface_tester = Class::Mock::Generic::InterfaceTester->new;
    My::Module->_storage_class($interface_tester);
    
    # Expect this method to be called by this test.
    $interface_tester->add_fixtures(
        fetch => {
            input => [customer_id => 94],
            output => ...
        },
    );
    ok(My::Module->something_that_fetches_from_storage(customer_id => 94));

    # Expect these two methods to be called by this next test.
    $interface_tester->add_fixtures(
        update => {
            input  => [status => 'fired', reason => 'non-payment'],
            output => 1,
        },
        uuid => {
            output => 'DEADBEEF-1234-5678-9ABC-1234567890AB',
        }
    );
    ok(My::Module->something_that_updates_storage_for_non_payment);

=head1 METHODS

=head2 new

This is the main method. It creates a very simple object. Pass to it a list or
arrayref of fixtures (see L<add_fixtures> for syntax). Any subsequent method
calls on that object are handled by AUTOLOAD. Note that because
the constructor is Highly Magical you can even provide fixtures for a
method called 'new()'.  The only ones you can't provide fixtures for are
'AUTOLOAD()' and 'DESTROY()', and possibly L<add_fixtures>.

For each method call, the first element is removed from the array of
fixtures.  We then compare the name of the method that was called with
the name of the method we *expected* to be called.  If it's wrong, a
test failure is emitted.  If that matches, we then compare the actual
parameters passed to the method with those in the fixture.  If they don't
match, then that's a test failure.  If they do match, then finally the
'output' specified in the fixture is returned.

Test failures will tell you what the error was, and where the object was created.

If you want to do anything more complicated than compare input exactly,
then specify a code-ref thus:

    {
        method => 'update',
        input  => sub { exists({@_}->{fruit}) && {@_}->{fruit} eq 'apple' },
        output => 94
    }

In this case, the actual parameters passed to the method will be passed to
that code-ref for validation.  It should return true if the params are OK
and false otherwise.  In the example, it will return true if the hash of
args contains a 'fruit' key with value 'apple'.

=head2 add_fixtures

Supplied with either an arrayref or a list of method call fixtures, adds them
to the array of fixtures this object maintains internally (although see below
for a caveat about this).

At the simplest, a method call fixture is a hashref with keys
C<method>, C<input> and C<output>. If you don't care about the input
your method receives, you can omit that key and any input will be accepted.

You can also provide a fixture as a pair of C<method> and (hashref containing
input and output). This lets you write a series of method call fixtures as an
apparent ordered hash, which may feel more natural. As above, you can omit
the input field if you don't care. So the following calls are equivalent:

 $interface_tester->add_fixtures(
     [
         {
             method => 'do_something',
             input  => sub { 1 },
             output => 'Yup, done',
         },
         {
             method => 'do_something_with_this',
             input  => ['fish'],
             output => 'Fish cooked',
         }
     ]
 );

 $interface_tester->add_fixtures(
     do_something           => { output => 'Yup, done' },
     do_something_with_this => {
         input  => ['fish'],
         output => 'Fish cooked',
     },
 );

Caveat: just in case you need to test a call to a method that coincidentally
is also called C<add_fixtures>, this method is only enabled
if you did I<not> provide a list of fixtures to the constructor. Note that this
means that you can't use C<add_fixtures> to add a fixture for a method called
C<add_fixtures>!

=head2 set_name

Takes a scalar parameter and spits that back out at you in any errors, which
may make debugging code that used this module easier. This method is only
available before you add fixtures. As soon as you add fixtures any calls to
C<set_name> are treated as normal mocked method calls.

=head2 DESTROY

When the mock object goes out of scope, this is called as usual.  It
will emit a test failure if not all the fixtures were used.

=head1 PHILOSOPHY

When you test a piece of code, you want to test it in isolation, because
that way when you get test failures it's much easier to find them than if
the code you're testing then calls other code, which calls three other
modules, which call other modules and so on.  If your tests end up running
a whole bunch of code other than just the little bit you actually want to
test then a failure in any one of those other parts can be very hard to
find and fix.

You also want to test all of your code's inputs and outputs.  Some inputs
and outputs are obvious - the parameters you pass to a method are inputs,
and its outputs include the return value and any changes in state that the
method call makes.  For example, in this accessor:

    package MyApp::SomeModule;

    sub fruit {
        my $self = shift;
        if(@_) { $self->{fruit} = shift; }
        return $self->{fruit};
    }

the inputs are the argument (if supplied), and the outputs are the return
value and, if you supplied an argument, the object's changed internal state.

So far, so easy to test.

Now consider a slightly more complex accessor:

    package MyApp::SomeModule;

    sub fruit {
        my $self = shift;
        if(@_) {
            $self->{fruit} = shift;
            $self->log(INFO, "fruit changed to ".$self->{fruit});
        }
        return $self->{fruit};
    }

    sub log {
        my $self = shift;
        my $priority = shift;
        my $message = shift;
        MyApp::Logger->log($priority, $message);
    }

This accessor has an extra output, the call to $self->log(), the method for
which is also shown.  But when you're testing the accessor, you don't really
want the hassle of setting up and configuring logging, nor do you really want to
run all the extra code that that entails, all of which is a potential source
of confusing test failures and should itself be run in isolation.  So, modify
the log() method thus:

    package MyApp::SomeModule;

    use Class::Mockable
        _logger => 'MyApp::Logger';

    sub log {
        my $self = shift;
        my $priority = shift;
        my $message = shift;
        $self->_logger()->log($priority, $message);
    }
    
and in the tests ...

    MyApp::SomeModule->_logger(
        Class::Mock::Generic::InterfaceTester->new([
            {
                method => 'log',
                input  => [INFO, "fruit changed to apple"],
                output => "doesn't matter for this test"
            }
        ])
    );

    ...
    ok($object->fruit('apple') eq 'apple',
        "'fruit' accessor returned the right value");
    ok($object->fruit() eq 'apple',
        "... yup, the object's internal state looks like it changed");

That mocks the logger, but still checks that your code called it correctly.
The mocking being in the log() method means that the only application code that
got run for this test is the fruit() accessor and the log() method - the logger
itself wasn't run, it was mocked - so we have proved that all of the fruit()
accessor's inputs and outputs, including the method calls that it makes, are
correct.

If the log() method call (and hence the call to the mocked logger) is correct,
then you shouldn't notice any changes in your tests.  But if the accessor's
calling of the log() method changes in any way without you also changing the
mock (which is effectively a test fixture) then you'll get test failures.

=head1 SEE ALSO

L<Test::MockObject> is good for faking up troublesome interfaces to
third-party systems - for example, for making a wee pretendy third
party web service that the code you're testing wants to talk to.  You want
to mock such things if the third party service is slow, or unreliable, or
not available in all your testing environments.  You could also use 
Class::Mock::Generic::InterfaceTester for this, but often Test::MockObject
is simpler.  Use Test::MockObject if you care mostly about the data you get
back from external code, use Class::Mock::Generic::InterfaceTester if you
care more about how you call external code.

=cut

my $_add_fixtures;

sub new {
    my $class = shift;

    # If we're mocking a new method, we don't want to reconstruct the mock
    # object.
    if(Scalar::Util::blessed($class)) {
        $AUTOLOAD = __PACKAGE__.'::new';
        return $class->AUTOLOAD(@_);
    }

    my($sub, $line, $file) = ((caller(1))[3], (caller(0))[2, 1]);
    my $caller = sprintf("defined in %s at line %d of %s", $sub, $line, $file);
    my $self = bless({
        called_from => $caller,
        tests => [],
    }, $class);
    $self->{_fixtures_have_been_set} = 0;
    if (@_) {
        $_add_fixtures->($self, @_);
    } else {
        $self->{_no_fixtures_in_constructor} = 1;
    }
    return $self;
}

# Declaring this as a coderef rather than a method so we can decide
# whether it exists or not based on how the constructor was called,
# for maximum backwards-compatibility.

$_add_fixtures = sub {
    my $self = shift;

    $self->{_fixtures_have_been_set} = 1;

    # We might have been passed an arrayref or a list.
    my @args = (ref($_[0]) eq 'ARRAY' && @_ == 1) ? @{$_[0]} : @_;

    # Our fixtures might be raw hashrefs, or method name => hashref pairs.
    # You can't mix and match.
    my @fixtures;
    if (ref($args[0]) eq 'HASH') {
        @fixtures = @args;
    } else {
        while (my ($method, $fixture_details) = splice(@args, 0, 2)) {
            push @fixtures, { method => $method, %$fixture_details };
        }
    }

    # If input is omitted, we assume we don't care.
    for (@fixtures) {
        if (!exists $_->{input}) {
            $_->{input} = sub { 1 };
        }
    }

    # OK, add these fixtures.
    push @{ $self->{tests} ||= [] }, @fixtures;
};

sub AUTOLOAD {
    (my $method = $AUTOLOAD) =~ s/.*:://;
    my $self = shift;
    my @args = @_;

    # If this is the special method add_fixtures, and we didn't
    # add fixtures in the constructor (i.e. we expect to add fixtures
    # bit by bit rather than all at once), add fixtures to our list.
    if ($method eq 'add_fixtures' && $self->{_no_fixtures_in_constructor}) {
        return $_add_fixtures->($self, @args);
    # If we haven't set any fixtures at all then we can assume that the
    # 'set_name' method is supposed to set this object's name
    } elsif($method eq 'set_name' && !$self->{_fixtures_have_been_set}) {
        $self->{called_from} = "'$args[0]' ".$self->{called_from};
        return;
    }

    # If we have no more tests, then we've called the mocked $thing more
    # times than expected - the code under test obviously has more outputs
    # than expected, which is Bad.
    if(!@{$self->{tests}}) {
        __PACKAGE__->_ok()->(0, sprintf (
            "run out of tests on mock object %s",
            $self->{called_from}
        ));
        return;
    }

    my $next_test = shift(@{$self->{tests}});

    # Check the correct method was called.  If it wasn't, then the code
    # under test's outputs are not what we expected (they are, at best
    # in the wrong order), which is Bad.
    if($next_test->{method} ne $method) {
        __PACKAGE__->_ok()->( 0,
            sprintf (
                "wrong method '%s' (expected '%s') called on mock object %s",
                $method,
                $next_test->{method},
                $self->{called_from},
            )
        );
        return;
    }

    # Now ensure that the input was as expected.  The fixture is normally
    # provided as an arrayref of expected params, which is (deeply) compared
    # to what was provided.  For more complicated stuff such as where you
    # are passing an object, or where you just want to check that the args
    # match a certain pattern (eg did the hash of args contain a 'fruit' key
    # with value 'apple') then pass in a code-ref.
    if (ref $next_test->{input} eq 'CODE') {
        # pass the args to the code, see if it says they're ok
        if(!$next_test->{input}->(@args)) {
            __PACKAGE__->_ok()->(0,
                sprintf (
                    "wrong args to mock object %s. Got %s.",
                    $self->{called_from},
                    Dumper(\@args)
                )
            );
        }
    } elsif (!Compare(\@args, $next_test->{input})) {
        __PACKAGE__->_ok()->( 0,
            sprintf (
                "wrong args to mock object %s (expected %s, got %s)",
                $self->{called_from},
                Dumper($next_test->{input}),
                Dumper(\@args)
            )
        );
        return;
    }
    return $next_test->{output};
}

sub DESTROY {
  my $self = shift;
  if(@{$self->{tests}}) {
    __PACKAGE__->_ok()->( 0,
        sprintf (
            "didn't run all tests in mock object %s (remaining tests: %s)",
            $self->{called_from},
            Dumper( $self->{tests} ),
        )
    );
  }
}
 
=head1 AUTHOR

Copyright 2012, 2017 UK2 Ltd and David Cantrell E<lt>david@cantrell.org.ukE<gt>

Some contributions from Sam Kington

This software is free-as-in-speech software, and may be used, distributed,
and modified under the terms of either the GNU General Public Licence
version 2 or the Artistic Licence.  It's up to you which one you use.  The
full text of the licences can be found in the files GPL2.txt and
ARTISTIC.txt, respectively.

=head1 SOURCE CODE REPOSITORY

E<lt>git://github.com/DrHyde/perl-modules-Class-Mockable.gitE<gt>

=head1 BUGS/FEEDBACK

Please report bugs at Github
E<lt>https://github.com/DrHyde/perl-modules-Class-Mockable/issuesE<gt>

=head1 CONSPIRACY

This software is also free-as-in-mason.

=cut

1;

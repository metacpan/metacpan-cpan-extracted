package Class::Mock::Method::InterfaceTester;

use strict;
use warnings;

our $VERSION = '1.2001';

# all this pre-amble is damned near identical to C::M::G::IT. Re-factor.
use Test::More ();
use Data::Compare;
use Scalar::Util qw(blessed);
use PadWalker qw(closed_over);
use Data::Dumper;
local $Data::Dumper::Indent = 1;

use Class::Mockable
    _ok => sub { Test::More::ok($_[0], @_[1..$#_]) };

use constant {
    DIDNT_RUN_ALL             => 'didn\'t run all tests in mock method defined in %s (remaining tests: %s)',
    RUN_OUT                   => 'run out of tests on mock method defined in %s',

    WRONG_ARGS                => 'wrong args to mock method defined in %s. Got %s',
    WRONG_ARGS_W_EXPECTED     => 'wrong args to mock method defined in %s. Got %s, expected %s',

    BOTH_INVOCANTS            => 'bad fixture %s, can\'t have invocant_object and invocant_class, defined in %s',
    EXP_CLASS_GOT_OBJECT      => 'expected call as class method, but object method called, defined in %s',
    EXP_OBJECT_GOT_CLASS      => 'expected call as object method, but class method called, defined in %s',
    WRONG_CLASS               => 'class method called on wrong class, defined in %s - got %s expected %s',
    WRONG_OBJECT              => 'object method called on object of wrong class, defined in %s - called on a %s, expected a %s',
    WRONG_OBJECT_SUBREF       => 'object method called on object which doesn\'t match specified sub-ref, defined in %s',
};

sub new {
    my $class = shift;
    my $called_from = (caller(1))[3];
    my @tests = @{shift()};

    return bless(sub {
        if(!@tests) { # no tests left
            return $class->_report_error(RUN_OUT, $called_from);
        }

        my $this_test = shift(@tests);
        my $invocant = shift;
        my @params = @_;

        # check arguments
        if(ref($this_test->{input}) eq 'CODE') {
            if(!$this_test->{input}->(@params)) {
                return $class->_report_error(WRONG_ARGS, $called_from, Dumper(\@params));
            }
        } elsif(!Compare($this_test->{input}, \@params)) {
                return $class->_report_error(WRONG_ARGS_W_EXPECTED, $called_from, Dumper(\@params), Dumper($this_test->{input}));
        }

        # check invocant
        if($this_test->{invocant_class} && $this_test->{invocant_object}) {
            return $class->_report_error(BOTH_INVOCANTS, Dumper($this_test), $called_from);
        } elsif($this_test->{invocant_class}) { # must be called as class method on right class
            if(ref($invocant)) {
                return $class->_report_error(EXP_CLASS_GOT_OBJECT, $called_from);
            } elsif($invocant ne $this_test->{invocant_class}) {
                return $class->_report_error(WRONG_CLASS, $called_from, $invocant, $this_test->{invocant_class});
            }
        } elsif($this_test->{invocant_object}) { # must be called as object method
            if(!blessed($invocant)) {
                return $class->_report_error(EXP_OBJECT_GOT_CLASS, $called_from);
            }
            if(ref($this_test->{invocant_object}) eq 'CODE') { # check via subref
                if(!$this_test->{invocant_object}->($invocant)) {
                    return $class->_report_error(WRONG_OBJECT_SUBREF, $called_from);
                }
            } elsif(blessed($invocant) ne $this_test->{invocant_object}) { # object must be right class
                return $class->_report_error(WRONG_OBJECT, $called_from, blessed($invocant), $this_test->{invocant_object});
            }
        }

        return $this_test->{output};
    }, $class);
}

sub _report_error {
    my($class, $error, @params) = @_;
    $class->_ok()->(0, sprintf($error, @params));
}

# re-factor this and C::M::G::IT::DESTROY
sub DESTROY {
  my $self = shift;
  my %closure = %{(closed_over($self))[0]};

  if(@{$closure{'@tests'}}) {
      $self->_report_error(DIDNT_RUN_ALL,  ${$closure{'$called_from'}}, Dumper( $closure{'@tests'} ));
  }
}

1;

=head1 NAME

Class::Mock::Method::InterfaceTester

=head1 DESCRIPTION

A helper for Class::Mockable's method mocking

=head1 SYNOPSIS

In the class under test:

    # create a '_foo' wrapper around method 'foo'
    use Class::Mockable
        methods => { _foo => 'foo' };

And then in the tests:

    Some::Module->_set_foo(
        Class::Mock::Method::InterfaceTester->new([
            {
                input  => ...
                output => ...
            }
        ])
    );

=head1 METHODS

=head2 new

This is the constructor.  It returns a blessed sub-ref.  Class::Mockable's
method mocking expects a sub-ref, so will Just Work (tm).

The sub-ref will behave similarly to the method calls defined in
Class::Mock::Generic::InterfaceTester.  That is, it will validate
that the method is being called correctly and emit a test failure if it
isn't, or if called correctly will return the specified value.  If the
method is ever called with the wrong parameters - including if defined
method calls are made in the wrong order - then that's a test failure.

It is also a test failure to call the method fewer or more times than
expected.  Calling it fewer times than expected will be detected very
late - when the subroutine goes away, so either at the end of the process
or when it is redefined, eg with _reset_... (see Class::Mockable).

C<new()> takes an arrayref of hashrefs as its argument.  Those hashes
must have keys 'input' and 'output' whose values define the ins and
outs of each method call in turn.  'input' is always an arrayref which
will get compared to all the method's arguments (excluding the first
one, the object or class itself) but for validating very complex inputs
you may specify a subroutine reference for the input, which will get
executed with the actual input as its argument, and emit a failure if
the call returns false.

If you want to check
that the method is being invoked on the right object or class (if you
are paranoid about inheritance, for example) then use the optional
'invocant_class' string to check that it's being called as a class method
on the right class (not on a subclass, *the right class*), or
invocant_object' string to check that it's being called on an object of
the right class (again, not a subclass), or 'invocant_object' subref to
check that it's being called on an object that, when passed to the sub-ref,
returns true.

=head1 SEE ALSO

L<Class::Mockable>

L<Class::Mock::Generic::InterfaceTester>

=head1 AUTHOR

Copyright 2013 UK2 Ltd and David Cantrell E<lt>david@cantrell.org.ukE<gt>

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

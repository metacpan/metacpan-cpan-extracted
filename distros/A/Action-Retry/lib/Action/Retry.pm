#
# This file is part of Action-Retry
#
# This software is copyright (c) 2013 by Damien "dams" Krotkine.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Action::Retry;
{
  $Action::Retry::VERSION = '0.24';
}

# ABSTRACT: Module to try to perform an action, with various ways of retrying and sleeping between retries.

use Module::Runtime qw(use_module);
use Scalar::Util qw(blessed);
use Time::HiRes qw(usleep gettimeofday);
use Carp;

use base 'Exporter';
our @EXPORT_OK = qw(retry);
# export by default if run from command line
our @EXPORT = ((caller())[1] eq '-e' ? @EXPORT_OK : ());

use Moo;



has attempt_code => (
    is => 'ro',
    required => 1,
    isa => sub { ref $_[0] eq 'CODE' },
);


has retry_if_code => (
    is => 'ro',
    required => 1,
    isa => sub { ref $_[0] eq 'CODE' },
    default => sub { sub { $_[0] }; },
);


has on_failure_code => (
    is => 'ro',
    isa => sub { ref $_[0] eq 'CODE' },
    predicate => 1,
);


has strategy => (
    is => 'ro',
    default => sub { 'Constant' },
    coerce => sub {
        my $attr = $_[0];
        blessed($attr)
          and return $attr;
        my $class_name = $attr;
        my $constructor_params = {};
        if (ref $attr eq 'HASH') {
            $class_name = (keys %$attr)[0];
            $constructor_params = $attr->{$class_name};
        }
        $class_name = $class_name =~ /^\+(.+)$/ ? $1 : "Action::Retry::Strategy::$class_name";
        return use_module($class_name)->new($constructor_params);
    },
    isa => sub { $_[0]->does('Action::Retry::Strategy') or croak 'Should consume the Action::Retry::Strategy role' },
);


has non_blocking => (
    is => 'ro',
    default => sub { 0 },
);

# For non blocking mode, store the timestamp after which we can retry
has _needs_sleeping_until => (
    is => 'rw',
    default => sub { 0 },
    init_arg => undef,
);


sub run {
    my $self = shift;

    while(1) {

        if (my $timestamp = $self->_needs_sleeping_until) {
            # we can't retry until we have waited enough time 
            my ($seconds, $microseconds) = gettimeofday;
            $seconds * 1000 + int($microseconds / 1000) >= $timestamp
              or return;
            $self->_needs_sleeping_until(0);
            $self->strategy->next_step;
        }

        my $error;
        my @attempt_result;
        my $attempt_result;
        my $wantarray;
          
        if (wantarray) {
            $wantarray = 1;
            @attempt_result = eval { $self->attempt_code->(@_) };
            $error = $@;
        } elsif ( ! defined wantarray ) {
            eval { $self->attempt_code->(@_) };
            $error = $@;
        } else {
            $attempt_result = eval { $self->attempt_code->(@_) };
            $error = $@;
        }

        my $h = { action_retry => $self,
                  attempt_result => ( $wantarray ? \@attempt_result : $attempt_result ),
                  attempt_parameters => \@_,
                };


        $self->retry_if_code->($error, $h )
          or $self->strategy->reset, $@ = $error, return ( $wantarray ? @attempt_result : $attempt_result );

        if (! $self->strategy->needs_to_retry) {
            $self->strategy->reset;
            $self->has_on_failure_code
              and return $self->on_failure_code->($error, $h);
            return;
        }

        if ($self->non_blocking) {
            my ($seconds, $microseconds) = gettimeofday;
            $self->_needs_sleeping_until($seconds * 1000 + int($microseconds / 1000) + $self->strategy->compute_sleep_time);
        } else {
            usleep($self->strategy->compute_sleep_time * 1000);
            $self->strategy->next_step;
        }
    }
}


sub retry (&;@) {
    my $code = shift;
    @_ % 2
      and croak "arguments to retry must be a CodeRef, and an even number of key / values";
    my %args = @_;
    Action::Retry->new( attempt_code => $code, %args )->run();
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Action::Retry - Module to try to perform an action, with various ways of retrying and sleeping between retries.

=head1 VERSION

version 0.24

=head1 SYNOPSIS

  # Simple usage, will attempt to run the code, retrying if it dies, retrying
  # 10 times max, sleeping 1 second between retries

  # functional interface
  use Action::Retry qw(retry);
  retry { do_stuff };
 
  # OO interface
  use Action::Retry;
  Action::Retry->new( attempt_code => sub { do_stuff; } )->run();



  # Same, but sleep time is doubling each time, and arguments passed to the
  # attempted code

  # OO interface
  my $action = Action::Retry->new(
    attempt_code => sub { my ($num, $str) = @_; ... },
    strategy => 'Linear',
  );
  my $result = $action->run(42, "foo");

  # functional interface
  retry { my ($num, $str) = @_;... } strategy => 'Linear';



  # Same, but sleep time is following the Fibonacci sequence

  # OO interface
  my $action = Action::Retry->new(
    attempt_code => sub { ... },
    strategy => 'Fibonacci',
  );
  $action->run();

  # functional interface
  retry { ... } strategy => 'Fibonacci';



  # The code to check if the attempt succeeded can be customized. Strategies
  # can take arguments. Code on failure can be specified.

  # OO way
  my $action = Action::Retry->new(
    attempt_code => sub { ... },
    retry_if_code => sub { $_[0] =~ /Connection lost/ || $_[1]->{attempt_result} > 20 },
    strategy => { Fibonacci => { multiplicator => 2000,
                                 initial_term_index => 3,
                                 max_retries_number => 5,
                               }
                },
    on_failure_code => sub { say "Given up retrying" },
  );
  $action->run();

  # functional way
  retry { ...}
    retry_if_code => sub { ... },
    strategy => { Fibonacci => { multiplicator => 2000,
                                 initial_term_index => 3,
                                 max_retries_number => 5,
                               }
                },
    on_failure_code => sub { ... };



  # Retry code in non-blocking way

  # OO way
  my $action = Action::Retry->new(
    attempt_code => sub { ...},
    non_blocking => 1,
  );
  while (1) {
    # if the action failed, it doesn't sleep
    # next time it's called, it won't do anything until it's time to retry
    $action->run();
    # do something else while time goes on
  }

=head1 ATTRIBUTES

=head2 attempt_code

  ro, CodeRef, required

The code to run to attempt doing the action. Will be evaluated taking care of
the caller's context. It will receive parameters that were passed to C<run()>

=head2 retry_if_code

  ro, CodeRef

The code to run to check if we need to retry the action. It defaults to:

  # Returns true if there were an exception evaluating to something true
  sub { $_[0] }

It will be given these arguments:

=over

=item * 

as first argument, a scalar which is the value of any exception that were
raised by the C<attempt_code>. Otherwise, undef.

=item *

as second argument, a HashRef, which contains these keys:

=over

=item action_retry

it's a reference on the ActionRetry instance. That way you can have access to
the strategy and other attributes.

=item attempt_result

It's a scalar, which is the result of C<attempt_code>. If C<attempt_code>
returned a list, then the scalar is the reference on this list.

=item attempt_parameters

It's the reference on the parameters that were given to C<attempt_code>.

=back

=back

C<retry_if_code> return value will be interpreted as a boolean : true return
value means the execution of C<attempt_code> was a failure and it needs to be
retried. False means it went well.

Here is an example of code that gets the arguments properly:

  my $action = Action::Retry->new(
    attempt_code => sub { do_stuff; } )->run();
    attempt_code => sub { map { $_ * 2 } @_ }
    retry_if_code => sub {
      my ($error, $h) = @_;

      my $attempt_code_result = $h->{attempt_result};
      my $attempt_code_params = $h->{attempt_parameters};

      my @results = @$attempt_code_result;
      # will contains (2, 4);

      my @original_parameters = @$attempt_code_params;
      # will contains (1, 2);

    }
  );
  my @results = $action->run(1, 2);

=head2 on_failure_code

  ro, CodeRef, optional

If given, will be executed when retries are given up.

It will be given the same arguments as C<retry_if_code>. See C<retry_if_code> for their descriptions

=head2 strategy

  ro, defaults to 'Constant'

The strategy for managing retrying times, sleeping, and giving up. It must be
an object that does the L<Action::Retry::Strategy> role.

This attribute has a coercion from strings and hashrefs. If you pass a string,
it will be treated as a class name (under C<Action::Retry::Strategy::>, unless
it is prefxed with a C<+>) to instantiate.

If you pass a hashref, the first key will be treated as a class name as above,
and the value of that key will be treated as the args to pass to C<new>.

Some existing stragies classes are L<Action::Retry::Strategy::Constant>,
L<Action::Retry::Strategy::Fibonacci>, L<Action::Retry::Strategy::Linear>.

Defaults to C<'Constant'>

=head2 non_blocking

  ro, defaults to 0

If true, the instance will be in a pseudo non blocking mode. In this mode, the
C<run()> function behaves a bit differently: instead of sleeping between
retries, the C<run()> command will immediately return. Subsequent call to
C<run()> will immediately return, until the time to sleep has been elapsed.
This allows to do things like that:

  my $action = Action::Retry->new( ... , non_blocking => 1 );
  while (1) {
    # if the action failed, it doesn't sleep
    # next time it's called, it won't do anything until it's time to retry
    $action->run();
    # do something else while time goes on
  }

If you need a more advanced non blocking mode and callbacks, then look at L<AnyEvent::Retry>

=head1 METHODS

=head2 run

Does the following:

=over

=item step 1

Runs the C<attempt_code> CodeRef in the proper context in an eval {} block,
saving C<$@> in C<$error>.

=item step 2

Runs the C<retry_if_code> CodeRef in scalar context, giving it as arguments
C<$error>, and the return values of C<attempt_code>. If it returns true, we
consider that it was a failure, and move to step 3. Otherwise, we consider it
means success, and return the return values of C<attempt_code>.

=item step 3

Ask the C<strategy> if it's still useful to retry. If yes, sleep accordingly,
and go back to step 2. If not, go to step 4.

=item step 4

Runs the C<on_failure_code> CodeRef in the proper context, giving it as
arguments C<$error>, and the return values of C<attempt_code>, and returns the
results back to the caller.

=back

Arguments passed to C<run()> will be passed to C<attempt_code>. They will also
passed to C<on_failure_code> as well if the case arises.

=head2 retry

  retry { ..code.. } some => 'arguments';

Is equivalent to 

  Action::Retry->new(attempt_code => sub { ..code.. }, some => arguments )->run();

A functional interface, alternative to the OO interface.

=head1 SRATEGIES

Here are the strategies currently included by default. Check their
documentation for more details.

=over

=item L<Action::Retry::Strategy::Constant>

Provides a simple constant sleep time strategy

=item L<Action::Retry::Strategy::Fibonacci>

Provides an incremental constant sleep time strategy following Fibonacci
sequence

=item L<Action::Retry::Strategy::Linear>

Provides a linear incrementing sleep time strategy

=back

=head1 SEE ALSO

I created this module because the other related modules I found didn't exactly
do what I wanted. Here is the list and why:

=over

=item L<Retry>

No custom checking code. No retry strategies. Can't sleep under one second. No
non-blocking mode. No custom failure code.

=item L<Sub::Retry>

No retry strategies. Can't sleep under one second. Retry code is
passed the results of the attempt code, but not the exception. No non-blocking mode. No custom failure code.

=item Attempt

No custom checking code. Strange exception catching behavior. No retry strategies. No non-blocking mode. No custom failure code.

=item AnyEvent::Retry

Depends on AnyEvent, and Moose. Strategies are less flexibles, and they don't have sleep timeouts (only max tries).

=back

=head1 AUTHOR

Damien "dams" Krotkine

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Damien "dams" Krotkine.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

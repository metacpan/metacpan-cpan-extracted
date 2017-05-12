package AE::AdHoc;

use warnings;
use strict;

=head1 NAME

AE::AdHoc - Simplified interface for tests/examples of AnyEvent-related code.

=head1 NON-DESCRIPTION

This module is NOT for introducing oneself to AnyEvent, despite the mention of
"simplified". More over, it REQUIRES knowledge of what a conditional variable,
or simply "condvar", is. See L<Anyevent::Intro>.

This module is NOT for building other modules, it's for running them with
minimal typing.

=head1 SYNOPSIS

Suppose we have a subroutine named C<do_stuff( @args, $subref )>
that is designed to run under AnyEvent. As do_stuff may have to wait for
some external events to happen, it does not return a value right away.
Instead, it will call C<$subref-E<gt>( $results )> when stuff is done.

Now we need to test do_stuff, so we set up an event loop. We also need a timer,
because a test that runs forever is annoying. So the script goes like this:

    use AnyEvent;

    # set up event loop
    my $cv = AnyEvent->condvar;
    my $timer = AnyEvent->timer(
        after => 10, cb => sub { $cv->croak("Timeout"); }
    );

    do_stuff( @args, sub{ $cv->send(shift); } );

    # run event loop, get rid of timer
    my $result = $cv->recv();
    undef $timer;

    # finally
    analyze_results( $result );

Now, the same with AE::AdHoc:

    use AE::AdHoc;

    my $result = ae_recv {
         do_stuff( @args, ae_send );
    } 10; # timeout
    analyze_results( $result );

=head1 EXPORT

Functions C<ae_recv>, C<ae_send>, C<ae_croak>, C<ae_begin>, C<ae_end>, and
C<ae_goal> are exported by default.

=head1 SUBROUTINES

B<Note>: Anywhere below, C<$cv> means L<AnyEvent>'s conditional variable
responsible for current event loop. See C<condvar> section of L<AnyEvent>.

=cut

our $VERSION = '0.0805';

use Carp;
use AnyEvent::Strict;
use Scalar::Util qw(weaken looks_like_number);

use Exporter;

BEGIN {
	our @ISA = qw(Exporter);
	our @EXPORT = qw(ae_recv ae_send ae_croak ae_begin ae_end ae_goal ae_action);
};

=head2 ae_recv { CODE; } [ $timeout ] %options;

The main entry point of the module.

Run CODE block, enter event loop and wait for $timeout seconds for callbacks
set up in CODE to fire, then die. Return whatever was sent via C<ae_send>.

$timeout must be a nonzero real number. Negative value means "run forever".
$timeout=0 would be ambigous, so it's excluded.

Options may include:

=over

=item * timeout - override the $timeout parameter (one timeout MUST be present).

=item * soft_timeout - Override $timeout, and don't die,
but return undef instead.

=back

Other functions in this module would die if called outside of C<ae_recv>.

=cut

# $cv is our so that it can be localized and act as a lock
our $cv;

# These are for error pretty-printing.
my $iter; # ++ every time
our $where; # "$file:$line[$iter]"

sub ae_recv (&@) { ## no critic
	my $code = shift;
	my $timeout = @_ % 2 && shift; # load bare timeout if present
	my %opt = @_;

	$timeout = $opt{timeout} || $opt{soft_timeout} || $timeout;

	# check we're not in event loop before dying
	$cv and _croak("Nested calls to ae_recv are not allowed");
	local $cv = AnyEvent->condvar;

	croak "Parameter timeout must be a nonzero real number"
		if (!$timeout or !looks_like_number($timeout));

	# find out where we are
	$iter++;
	my @caller = caller(0);
	local $where = "ae_recv[$iter] at $caller[1]:$caller[2]";

	my $on_timeout = $opt{soft_timeout}
		? sub { $cv->send }
		: sub { $cv->croak("Timeout after $timeout seconds"); };
	my $timer;
	$timeout > 0 and $timer = AnyEvent->timer( after => $timeout,
		cb => $on_timeout,
	);
	_clear_goals();
	$code->();
	return $cv->recv;
	# on exit, $timer is autodestroyed
	# on exit, $cv is restored => destroyed
};

=head2 ae_send ( [@fixed_args] )

Create callback for normal event loop ending.

Returns a sub that feeds its arguments to C<$cv-E<gt>send()>. Arguments given to
the function itself are prepended, as in
C<$cv-E<gt>send(@fixed_args, @callback_args)>.

B<NOTE> that ae_recv will return all sent data "as is" in list context, and
only first argument in scalar context.

May be called as ae_send->( ... ) if you want to stop event loop immediately
(i.e. in a handcrafted callback).

=head2 ae_croak ( [$fixed_error] )

Create callback for event loop termination.

Returns a sub that feeds its first argument to $cv->croak(). If argument is
given, it will be used instead.

=head2 ae_begin ( [ sub { ... } ] )

=head2 ae_end

These subroutines provide ability to wait for several events to complete.

The AnyEvent's condition variable has a counter that is incremented by
C<begin()> and decreased by C<end()>. Optionally, the C<begin()> function
may also set a callback.

Whenever the counter reaches zero, either that callback or just C<send()> is
executed on the condvar.

B<Note>: If you do provide callback and want the event loop to stop there,
consider putting C<ae_send-E<gt>( ... )> somewhere inside the callback.

B<Note>: C<ae_begin()> acts at once, and does NOT return a closure. ae_end,
however, returns a subroutine reference just like C<ae_send>/C<ae_croak> do.

See begin/end section in L<AnyEvent>.

=cut

# set prototypes
sub ae_send (@); ## no critic
sub ae_croak (;$); ## no critic
sub ae_end (); ## no critic

# define ae_send, ae_croak and ae_end at once
foreach my $action (qw(send croak end)) {
	my $name = "ae_$action";
	my $code = sub {
		my @args = @_;

		croak("$name called outside ae_recv") unless $cv;
		my $myiter = $iter; # remember where cb was created

		my @caller = caller(0);
		my $exact = "$name at $caller[1]:$caller[2] from $where";

		return sub {
			return _error( "Leftover $exact called outside ae_recv" )
				unless $cv;
			return _error( "Leftover $exact called in $where")
				unless $iter == $myiter;
			$cv->$action(@args, @_);
		}; # end closure
	}; # end generated sub
	no strict 'refs'; ## no critic
	no warnings 'prototype'; ## no critic
	*{$name} = $code;
};

sub ae_begin(@) { ## no critic
	croak("ae_begin called outside ae_recv") unless $cv;

	$cv->begin(@_);
};


=head1 ADVANCED MULTIPLE GOAL INTERFACE

=head2 ae_goal( "name", @fixed_args )

Create a named callback.

When callback is created, a "goal" is set.

When such callback is called, anything passed to it is saved in a special hash
as array reference (prepended with @fixed_args, if any).

When all goals are completed, the hash of results is returned by C<ae_recv>.

If ae_send is called at some point, the list of incomplete and complete goals
is still available via C<goals> and C<results> calls.

The goals and results are reset every time upon entering ae_recv.

=cut

my %goals;
my %results;
sub _clear_goals { %goals = (); %results = (); };

sub ae_goal {
	my ($name, @fixed_args) = @_;

	croak "ae_goal called outside ae_recv" unless $cv;
	my $myiter = $iter;

	my @caller = caller(0);
	my $exact = "ae_goal('$name') at $caller[1]:$caller[2] from $where";

	$goals{$name}++ unless $results{$name};
	return sub {
		return _error( "Leftover $exact called outside ae_recv" )
			unless $cv;
		return _error( "Leftover $exact called in $where")
			unless $iter == $myiter;
		$results{$name} ||= [ @fixed_args, @_ ];
		delete $goals{$name};
		$cv->send(\%results) unless %goals;
	};
};

=head2 AE::AdHoc->goals

Return goals not yet achieved as hash ref.

=head2 AE::AdHoc->results

Return results of completed goals as hash ref.

=cut

sub goals { return \%goals; };
sub results { return \%results; };

=head1 ADDITIONAL ROUTINES

=head2 ae_action { CODE } %options

Perform CODE after entering the event loop via ae_recv
(a timer is used internally).

CODE will NOT run after current event loop is terminated (see ae_recv).

Options may include:

=over

=item * after - delay before code execution (in seconds, may be fractional)

=item * interval - delay between code executions (in seconds, may be fractional)

=item * count - how many times to execute. If zero or omitted, means unlimited
execution when interval is given, and just one otherwise.

=back

=cut

sub ae_action (&@) { ## no critic
	my $code = shift;
	my %opt = @_;

	# TODO copypaste from ae_goal, make a sub
	croak "ae_action called outside ae_recv" unless $cv;
	my $myiter = $iter;
	my @caller = caller(0);
	my $exact = "ae_action at $caller[1]:$caller[2] from $where";

	$opt{after} ||= 0;

	my $count = $opt{count};
	my $inf = !$count;
	my $n = 0;

	my $timer;
	my $cb = sub {
		if (!$cv) {
			undef $timer;
			return _error( "Leftover $exact called outside ae_recv" );
		};
		$myiter == $iter or undef $timer;
		$inf or $count-->0 or undef $timer;
		$timer and $code->($n++);
	};
	$timer = AnyEvent->timer(
		after=>$opt{after}, interval=>$opt{interval}, cb=>$cb);
	return;
};

=head1 ERROR HANDLING

Dying within event loop is a bad idea, so we issue B<warnings> and write
errors to magic variables. It is up to the user to check these variables.

=over

=item * C<$AE::AdHoc::errstr> - last error (as in L<::DBI>).

=item * C<@AE::AdHoc::errors> - all errors.

=item * C<$AE::AdHoc::warnings> - set this to false to suppress warnings.

=back

=cut

our @errors;
our $errstr;
our $warnings = 1; # by default, complain loudly

sub _error {
	$errstr = shift;
	push @errors, $errstr;
	carp __PACKAGE__.": ERROR: $errstr" if $warnings;
	return;
};
sub _croak {
	_error(@_);
	croak shift;
};

=head1 CAVEATS

This module is still under heavy development, and is subject to change.
Feature/change requests are accepted.

=head2 Callback confinement

If event loop is entered several times, the callbacks created in one
invocations will NOT fire in another. Instead, they'll issue a warning
and return (see "Error handling" below).

Error message will be like C<ae_send at file:13 from ae_recv[1] at file:12
called in ae_recv[2] at file:117>

This is done so to isolate invocations as much as possible.

However, detection of "this invocation" will go wrong if callback maker is
called in a callback itself. For instance, this will always work the same:

	# ...
        callback => sub { ae_send->(@_); },
	# ...

=cut

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ae-adhoc at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AE-AdHoc>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AE::AdHoc


You can also look for information at:

=over 4

=item * github:

L<https://github.com/dallaylaen/perl-AE-AdHoc>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AE-AdHoc>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AE-AdHoc>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AE-AdHoc>

=item * Search CPAN

L<http://search.cpan.org/dist/AE-AdHoc/>

=back

=head1 SEE ALSO

L<AnyEvent>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of AE::AdHoc

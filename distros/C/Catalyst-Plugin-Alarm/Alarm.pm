package Catalyst::Plugin::Alarm;
use base qw/Class::Accessor::Fast/;

use warnings;
use strict;

use Carp;
use Data::Dumper;
use Time::HiRes;

use Catalyst::Exception ();
use MRO::Compat;
use mro 'c3';

# Sys::SigAction doesn't help on Win32 systems
# because Win32 doesn't use POSIX signals
our $USE_NATIVE_SIGNALS = 0;
if ( $^O eq 'MSWin32' ) {
    $USE_NATIVE_SIGNALS = 1;
}

our $VERSION       = 0.05;
our $TIMEOUT       = 180;
our $LOCAL_TIMEOUT = 30;

# add a \. if we ever support HiRes alarm()
my $ALARM_RE = qr/^[\d]+$/;

BEGIN {
    __PACKAGE__->mk_accessors(qw/ alarm /);
}

sub setup_finalize {
    my $c   = shift;
    my $ret = $c->next::method(@_);

    my %conf = %{ $c->config->{alarm} };

    if ( $conf{use_native_signals} ) {
        $USE_NATIVE_SIGNALS = 1;
    }
    else {
        require Sys::SigAction;    # defer till runtime
    }

    return $ret;
}

# must call on every request
sub prepare {
    my $class = shift;
    my $c     = $class->next::method(@_);

    return $c unless exists $c->config->{alarm};

    my %alarm;

    # copy of config for easy checking and temp overriding
    my %conf = %{ $c->config->{alarm} };

    # should we override forward method?
    $alarm{forward} = $conf{forward} || 0;

    # check if we should override forward() based on regex
    if (    exists $conf{timeout}
        and exists $conf{override}
        and $conf{timeout} )
    {
        my $re = $conf{override}->{re} || '';
        if ( $re && $c->req->path =~ m/$re/ ) {
            $alarm{override} = $c->req->path;
            if ( $c->debug ) {
                $c->log->debug(
                    "found alarm override for: " . $c->req->path );
                $c->log->debug( "setting this request global alarm to "
                        . $conf{override}->{timeout} );
            }
            $conf{global} = $conf{override}->{timeout};
        }
    }

    # special case - allow for disable global timer
    if ( exists $conf{global}
        && $conf{global} != 0 )
    {
        my $timeout = $conf{global};

        my $handler = $conf{handler}
            || sub {
            Catalyst::Exception->throw("Global Alarm timeout: $timeout");
            };

        if ( !$timeout or $timeout !~ m/$ALARM_RE/ ) {

            # avoid spurious warning
            no warnings;

            #$timeout = '' unless defined $timeout;
            Catalyst::Exception->throw(
                "Global Alarm timeout value is invalid: $timeout");
        }

        # configure alarm
        $alarm{timeout} = $timeout;
        $alarm{start}   = [ Time::HiRes::gettimeofday() ];
        $alarm{handler} = $handler;
        $alarm{failed}  = [];

        my $alarm_handler = sub {
            $c->alarm->on(1);
            $c->alarm->sounded( Time::HiRes::gettimeofday() );
            $c->error(
                "Global Alarm sounded at ~$timeout seconds: "
                    . Time::HiRes::tv_interval(
                    $c->alarm->start, $c->alarm->sounded
                    )
            );

            push( @{ $c->alarm->{failed} }, $c->action->name );
            &$handler( $c, 1 );
        };

        if ($USE_NATIVE_SIGNALS) {
            $SIG{ALRM} = $alarm_handler;
        }
        else {

            $alarm{sig_handler}
                = Sys::SigAction::set_sig_handler( 'ALRM', $alarm_handler,
                { safe => 1 } );

        }

        # set alarm -- see NOTE in timeout about HiRes::alarm()
        #Time::HiRes::alarm($timeout);
        CORE::alarm($timeout);

        $c->log->debug("global alarm set for $timeout seconds")
            if $c->debug;

    }

    # set accessor
    $c->alarm( bless \%alarm, 'Catalyst::Alarm' );

    return $c;
}

sub finalize {
    my $c = shift;

    if ( !$c->alarm || !$c->alarm->{start} ) {
        $c->next::method(@_);
        return 1;
    }

    # this stuff may all be irrelevant since next::method
    # has already been called, but for completeness' sake.

    $c->alarm->stop( Time::HiRes::gettimeofday() );
    $c->alarm->total(
        Time::HiRes::tv_interval( $c->alarm->{start}, $c->alarm->{stop} ) );

    # turn off alarm
    #Time::HiRes::alarm(0);
    CORE::alarm(0);

    # debugging
    #$c->log->dumper($c->alarm);

    # SigAction reference count gets screwy sometimes (at least in tests)
    # so just delete this explicitly since we no longer need it anyway
    delete $c->alarm->{sig_handler};

    $c->next::method(@_);

    1;
}

sub forward {
    my $c = shift;

    # in Catalyst 5.8x stack is undef when we need it
    # so prime it here.
    $c->{stack} = [] unless $c->stack;

    if ( $c->alarm && $c->alarm->{forward} ) {
        return $c->timeout(@_);
    }

    return $c->dispatcher->forward( $c, @_ );
}

sub timeout {
    my $c = shift;
    my ( $timeout, @arg );

    # set a default if not configured
    my $conf = {};
    if ( !exists $c->config->{alarm} ) {
        $conf->{timeout} = $LOCAL_TIMEOUT;
    }
    else {
        $conf = $c->config->{alarm};
    }

    if ( ref $_[0] ) {
        $timeout = $_[0]->{timeout} || $conf->{timeout};
        @arg = ref $_[0]->{action} ? @{ $_[0]->{action} } : $_[0]->{action};
    }
    elsif ( !( @_ % 2 ) ) {
        my %e = @_;
        $timeout = $e{timeout} || $conf->{timeout};
        @arg = ref $e{action} ? @{ $e{action} } : $e{action};

        # just in case we called as 'foo',[@args] and not as => pairs
        if ( !scalar(@arg) || !defined $arg[0] ) {
            @arg = @_;
        }

    }
    else {
        @arg     = @_;
        $timeout = $conf->{timeout};
    }

    if ( !defined $timeout or $timeout !~ m/$ALARM_RE/ ) {

        # avoid spurious warning
        no warnings;
        Catalyst::Exception->throw(
            "Alarm timeout value is invalid: $timeout");
    }

    my $e = join( ', ', @arg );
    my @ret;
    $c->alarm->on(0);

    my $handler = $c->config->{alarm}->{handler}
        || sub { Catalyst::Exception->throw("Local Alarm timeout for: $e") };

    my $prev_alarm = 0;

    my $alarm_handler = sub {
        $c->alarm->on(1);
        push @{ $c->alarm->{failed} }, $e;

        $c->error(
            "Local Alarm sounded after $timeout seconds for action: $e");

        &$handler( $c, \@ret );

    };

    eval {
        my $h = $SIG{ALRM};
        if ($USE_NATIVE_SIGNALS) {
            $SIG{ALRM} = $alarm_handler;
        }
        else {
            $h = Sys::SigAction::set_sig_handler( 'ALRM', $alarm_handler,
                { safe => 1 } );
        }

        #$c->log->debug( Dumper $h );
        my $sv = [ Time::HiRes::gettimeofday() ];

      #$c->log->debug("setting alarm for $timeout seconds");
      # Time::HiRes version of alarm() doing wacky things like going off after
      # only 1.4.. seconds when $timeout is much greater
      # TODO see if I am just using it wrong.
      #my $prev_alarm = Time::HiRes::alarm($timeout);
        $prev_alarm = CORE::alarm($timeout);
        $c->log->debug("previous alarm was $prev_alarm")
            if $c->debug;

        @ret = $c->dispatcher->forward( $c, @arg );

        # NOTE that on alarm, if the default handler is used, we never
        # reach this point. This exists mostly for debugging
        # with the test scripts.

        #$c->log->debug("came back");
        my $ev = [ Time::HiRes::gettimeofday() ];
        my $intv = Time::HiRes::tv_interval( $sv, $ev );

        #warn "intv = $intv\n";
        $c->log->debug("resetting alarm after $intv seconds")
            if $c->debug;

        #Time::HiRes::alarm(0);

        # if $prev_alarm was set, then we are running under a global alarm
        # so do our best to restore it, minus the time we just spent
        # NOTE that because CORE alarm uses only ints that we end
        # up taking longer for global alarm than originally configed.
        if ( $prev_alarm > 0 ) {
            $prev_alarm = $prev_alarm - int($intv);
            $prev_alarm = 1 if $prev_alarm <= 0;
            $c->log->debug("prev_alarm = $prev_alarm")
                if $c->debug;
        }

        CORE::alarm($prev_alarm);

        if ($USE_NATIVE_SIGNALS) {
            $SIG{ALRM} = $h;
        }
    };

    # reset no matter what.
    #Time::HiRes::alarm(0);

    CORE::alarm($prev_alarm);

    # despite the forward() pod claim to the contrary,
    # there is a bug in Catalyst::forward() that returns
    # in scalar context, so only first return value is used.
    # we must mimic that behaviour until the bug is fixed.
    # Otherwise, we'll break existing code that relies on
    # that scalar behaviour.

    return $c->alarm->on ? undef : $ret[0];
}

1;

# C::A package is simple accessors and off() method
package Catalyst::Alarm;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(
    qw/
        timeout
        start
        stop
        total
        sig_handler
        handler
        failed
        sounded
        forward
        override
        on
        /
);

sub off {

    #Time::HiRes::alarm(0);
    CORE::alarm(0);
}

# for those who sleep like I do...
sub snooze { off() }

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Alarm - call an action with a timeout value

=head1 SYNOPSIS

 package MyApp;
 use Catalyst qw( Alarm );
 MyApp->config( alarm => {
    timeout => 60,
    global  => 120,
    handler => sub { # do something if alarm sounds }
 });
 
 sub default : Private {
     my ($self,$c) = @_;
     unless( $c->timeout('foo') ) {
        $c->stash->{error} = "Sorry to keep you waiting. There was a problem.";
        return;
     }
 }
 
 sub foo : Private {
    my ($self,$c) = @_;
    sleep 61;  
 }
 
=head1 DESCRIPTION

Catalyst::Plugin::Alarm implements the timeout_call() function of Sys::SigAction
for both global and local alarms.

You may set a global timeout value that will trigger alarm if the total processing
time of any request exceeds N seconds.

You may call individual actions with timeout values in a manner similar to the
standard forward() method.

B<NOTE:> Using alarms in a web application is not without peril, as any number of factors
could contribute to legitimately slowing down your application. The Alarm plugin should
be used only when you need to catch things that a browser's timeout feature won't catch.

=head1 CONFIGURATION

You may set default values in your config() hash, using the C<alarm> key.
Timeout values should be indicated in seconds and 
B<must> be integers. The added float granularity of Time::HiRes is not available
for the alarm values due to the way sleep() and alarm() interact (i.e., they
do not play together predictably).


=over

=item timeout I<N>

The default time to wait in the timeout() method.

=item global I<N>

The default time to wait for the entire request to finish. Default time is
three minutes (180 seconds). If your app will legitimately take longer than
that to finish a request, you should set it higher.

To disable global timeouts entirely, set I<N> to C<0>.

=item handler I<coderef>

Set a handler for timeouts. Will be used in both global timeouts and the
timeout() method. The default is to throw() a Catalyst::Exception with a
(hopefully) helpful message about the alarm.

I<coderef> can expect to receive the following arguments:

=over

=item $controller

The current controller object.

=item \@return or 1

If the alarm is the global alarm, the second value in @_ will be a 1. If the alarm
is a local alarm (from timeout() or forward()) then the second value will be a reference
to the array returned from your forwarded action.

The on() flag is significant in this case because if false, then the @return value will
be returned from the timeout() method. Otherwise, if on() is true, timeout() will
return undef.

Thus you can make alarms non-fatal by defining a handler that just notifies you
when an alarm went off and resetting the on() flag.

Example:

  __PACKAGE__->config( alarm => {
    handler => sub {
        if (ref $_[1]) {
            $_[0]->log->error(" .... local alarm went off!!");
            $_[1]->[0] = 'some return value';
            $_[0]->alarm->on(0);    # turn 'off' the alarm flag
        }
        else {
            $_[0]->log->error(" .... global alarm went off");
            $_[0]->alarm->on(1);
        }
    }
  });

=back

=item override

Configure a temporary override of the global timeout value based on a regular
expression match against $c->request->path().

Example:

 __PACKAGE__->config( alarm => {
    override => {
        re=> qr{/ajax/}, 
        timeout=> 3
    }
 });
 
Will set the global timeout value to 3 if the request->path matches C</ajax>.
The global timeout value will persist only for the life of that request.

=item forward

Use forward() directly instead of timeout(). Useful if you want to always call timeout(),
as with existing forward() code that you don't want to re-write to use timeout().

Example:

 __PACKAGE__->config( alarm => { 
    forward => 1, 
    timeout => 10 
 });
 
Will automatically call timeout() with a default value of 10 seconds, wherever your
code calls forward().

B<NOTE:> You must assign a default C<timeout> value to use the C<forward>
feature.

=item use_native_signals

Default value is false. If set to a true value, Sys::SigAction will not be used
and instead the built-in %SIG handlers will be used. This is necessary for the plugin
to work under Win32 systems and in some cases with FCGI.

=back


=head1 METHODS

=head2 alarm

Access the Catalyst::Alarm object.

B<NOTE:> This object won't exist if you do not configure the alarm.

See Catalyst::Alarm METHODS section below.

=head2 timeout( I<stuff_to_forward> )

A wrapper around the standard forward() call.

If the I<stuff_to_forward> has not returned before the alarm goes off,
timeout() will return undef and an error is set with the error() method.

On success, returns same thing forward() would return.

If you set a default C<timeout> value in config(), you can use timeout() just like forward().
If you want to override any default timeout value, pass either a hashref or an array of
key/value pairs. The supported key names are C<action> and C<timeout>.

Examples:

    $c->timeout( 'action' );  # use default timeout (throws exception if not set)

    $c->timeout( 
        action  => 'action',
        timeout => 40,    # override any defaults
    );

    $c->timeout( {  # or as a hashref
        timeout => 40,
        action  => [ qw/MyApp::Controller::Bar snafu/, ['some option'] ],
    });


=head2 setup_finalize

Overridden internally.

=head2 prepare

Overridden internally.

=head2 forward

Overridden internally.

=head2 finalize

Overridden internally.

=head1 Catalyst::Alarm METHODS

=head2 off

The Catalyst::Alarm object has one non-accessor method: off.

The off() method will turn all alarms off, including the global alarm. If you 
later call timeout() in the same request cycle, the alarm will be reset as indicated
in timeout().

An alias for off() is snooze(), which amuses the author.
The metaphor collapses in one important way:
snooze() turns off the alarm completely for the entire request cycle.

Example:

 __PACKAGE__->config( alarm => {
    override => {
        re      => qr{/foo/},
        timeout => 3 
    }
 });
 
 sub foo : Global {
   my ($self,$c) = @_;
   $c->alarm->off;      # negates the override in config
   $c->alarm->snooze;   # same thing as off()
   $c->timeout('bar');  # but set default alarm for 'bar'
 }

B<NOTE:> The off() method does not set the stop() time.

=head2 Alarm object accessors

You probably don't want to muck around with setting
anything, but you can get the following values:

=over

=item timeout

The global timeout value.

=item sounded

If the global alarm went off, this value is set to a
Time::HiRes::gettimeofday() result.

=item sig_handler

The Sys::SigAction object.

=item handler

The coderef used in case of alarm.

=item start

The time alarm was set. A Time::HiRes::gettimeofday() result.

=item stop

The time alarm was turned off. A Time::HiRes::gettimeofday() result.

=item total

The total run time the alarm was on. A Time::HiRes::tv_interval() result using
C<start> and C<stop>.

=item failed

An arrayref of the methods where an alarm sounded. If a global alarm sounded,
the value of $c->action->name is used.

=item forward

Whether or not the C<forward> config option was on.

=item override

If the C<override> config option was used and there was a successful match against
the regular expression, this method returns the request path that matched.

=item on

Flag that indicates whether the alarm sounded or not. True means that the alarm sounded.
If you set this flag to 0 (false), then the alarm will be ignored in timeout(). See
the C<handler> configuration option for more details about manipulating alarm responses.

=back

B<NOTE:> Because of where C<stop> and C<total> are set in the lifecycle of the request,
they are likely not accessible in your View. Thus
they are likely useless to you and exist for the amusement of the author, debugging,
and perhaps other plugins that may make use of them.


=head1 BUGS

Using a global alarm together with the C<forward> config feature can have unforeseen
behaviour. Most likely your global alarm will not work at all or may take a lot longer
to go off than you expect.

The Time::HiRes alarm() function ought to be used internally instead of the CORE alarm()
function, but it behaved unpredictably in the test cases. See the comments in the source
for more details.

Win32 systems don't have alarm() or other signal handlers, so B<use_native_signals>
gets turned on if running under Win32.

Some users report that Sys::SigAction does not play nicely with FCGI,
so you can set the B<use_native_signals> to a true value to use the built-in
%SIG handlers instead of Sys::SigAction.

=head1 AUTHOR

Peter Karman <pkarman@atomiclearning.com>.

=head1 CREDITS

Thanks to Bill Moseley and Yuval Kogman for feedback and API suggestions.

Thanks to Nilson Santos Figueiredo Junior for the Win32 suggestions.

=head1 COPYRIGHT

Copyright 2006 by Atomic Learning, Inc. All rights reserved.

This code is licensed under the same terms as Perl itself.

=head1 SEE ALSO

http://modperlbook.org/html/ch06_10.html,
L<DBI>, L<Sys::SigAction>, L<Time::HiRes>


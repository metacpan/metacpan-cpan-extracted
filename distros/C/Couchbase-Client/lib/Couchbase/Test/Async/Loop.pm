package Couchbase::Test::Async::Loop;
use strict;
use warnings;
use Couchbase::Client::Async;
use Couchbase::Client::IDXConst;
use Couchbase::Client::Errors;

use POE;
use POE::Kernel;
use POE::Session;
use Data::Dumper;
use Log::Fu { level => "info" };
use Devel::Peek;
use Array::Assign;

use base qw(POE::Sugar::Attributes);

my $poe_kernel = "POE::Kernel";

sub cbc_connect :Start {
    $_[HEAP]->object->connect();
}

sub unhandled :Event(_default) {
    log_errf("Got unknown event %s", $_[ARG0]);
}

sub got_error :Event {
    log_errf("Got errnum=%d, errstr=%s",
             $_[ARG0], $_[ARG1]);
    $_[HEAP]->on_error(@_[ARG0,ARG1]);
}


#This would be an event-loop specific implementation of update_event
my %EVMETH_MAP = (
    COUCHBASE_WRITE_EVENT, "write",
    COUCHBASE_READ_EVENT, "read"
);

sub _activate_events {
    my ($cbc_flags, $dupfh, $opaque) = @_;
    while (my ($ev,$meth) = each %EVMETH_MAP ) {
        if($cbc_flags & $ev) {
            log_debugf("Activating event %d on dupfd %d", $ev, fileno($dupfh));
            $poe_kernel->${\"select_$meth"}($dupfh, "dispatch_event", $ev, $opaque);
        }
    }
}

sub _deactivate_events {
    my ($cbc_flags, $dupfh) = @_;
    while (my ($ev,$meth) = each %EVMETH_MAP ) {
        if($cbc_flags & $ev) {
            log_debugf("Deactivating event %d on dupfd %d", $ev, fileno($dupfh));
            $poe_kernel->${\"select_$meth"}($dupfh);
        }
    }
}

sub _startstop_events {
    my ($events,$prefix,$dupfh) = @_;
    while (my ($ev,$meth) = each %EVMETH_MAP) {
        if($events & $ev) {
            log_debugf("Invoking $prefix: $meth on dupfd %d", fileno($dupfh));
            $poe_kernel->${\"$prefix\_$meth"}($dupfh);
        }
    }
}


sub update_event :Event {
    my ($evdata,$action,$flags) = @_[ARG0..ARG2];
    my $dupfh = $evdata->[EVIDX_DUPFH];
    
    if($action == EVACTION_WATCH) {
        if(!$dupfh) {
            open $dupfh, ">&", $evdata->[EVIDX_FD];
            _activate_events($flags, $dupfh, $evdata->[EVIDX_OPAQUE]);
            $evdata->[EVIDX_DUPFH] = $dupfh;
        } else {
            my $events_do_delete = $evdata->[EVIDX_WATCHFLAGS] & (~$flags);
            log_debugf("Old events=%x, new events = %x, delete events %x",
                       $evdata->[EVIDX_WATCHFLAGS], $flags, $events_do_delete);
            _activate_events($flags, $dupfh, $evdata->[EVIDX_OPAQUE]);
            _deactivate_events($events_do_delete, $dupfh);
        }
    } elsif ($action == EVACTION_UNWATCH) {
        if(!$dupfh) {
            warn("Unwatch requested on undefined dup'd filehandle");
            return;
        }
        _deactivate_events($evdata->[EVIDX_WATCHFLAGS], $dupfh);
    } elsif ($action == EVACTION_SUSPEND || $action == EVACTION_RESUME) {
        if(!$dupfh) {
            warn("suspend/resume requested on undefined dup'd filehandle. ".
                 "fd=".$evdata->[EVIDX_FD]);
        }
        my $prefix = $action == EVACTION_SUSPEND ? "pause" : "resume";
        $prefix = "select_" . $prefix;
        _startstop_events($evdata->[EVIDX_WATCHFLAGS], $prefix, $dupfh);
    } else {
        die("Unhandled action $action");
    }
}

sub update_timer :Event {
    my ($evdata,$action,$usecs) = @_[ARG0..ARG2];
    my $timer_id = $evdata->[EVIDX_PLDATA];
    my $seconds;
    
    if($usecs) {
        $seconds = ($usecs / (1000*1000));
    }
    if($action == EVACTION_WATCH) {
        if(defined $timer_id) {
            log_debugf("Rescheduling timer %d in %0.5f seconds from now",
                       $timer_id, $seconds);
            $poe_kernel->delay_adjust($timer_id, $seconds)
        } else {
            $timer_id = $poe_kernel->delay_set(
                "dispatch_timeout", $seconds, $evdata->[EVIDX_OPAQUE]);
            $evdata->[EVIDX_PLDATA] = $timer_id;
            log_debugf("Scheduling timer %d for %0.5f seconds from now",
                       $timer_id, $seconds);
        }
    } else {
        if(defined $timer_id) {
            log_debug("Deletion requested for timer $timer_id.");
            $poe_kernel->alarm_remove($timer_id);
            $evdata->[EVIDX_PLDATA] = undef;
        } else {
            log_debug("Requested to delete non-existent timer ID");
        }
    }
}

#this is what an event loop does in order to tell libcouchbase that an event
#has been received
sub dispatch_event :Event {
    my ($flags,$opaque) = @_[ARG2..ARG3];
    log_debugf("Flags=%d, opaque=%x", $flags, $opaque);
    Couchbase::Client::Async->HaveEvent($flags, $opaque);
}

sub dispatch_timeout :Event {
    my $opaque = $_[ARG0];
    my $flags = 0;
    log_debugf("Dispatching timer.. opaque=%x", $opaque);
    Couchbase::Client::Async->HaveEvent($flags, $opaque);
}


#### External interface

use Class::XSAccessor {
    constructor => 'new',
    accessors => [qw(object alias on_ready on_error)]
};

sub spawn {
    my ($cls,$session_name,%options) = @_;
    my $cb_ready = delete $options{on_ready}
        or die ("Must have on_ready callback");
    my $user_error_callback = delete $options{on_error};
    
    my $async = Couchbase::Client::Async->new({
        %options,
        cb_error =>
            sub { $poe_kernel->post($session_name, "got_error", @_) },
        cb_update_event =>
            sub { $poe_kernel->call($session_name, "update_event", @_) },
            
        cb_waitdone => $cb_ready,
        
        cb_update_timer =>
            sub { $poe_kernel->call($session_name, "update_timer", @_) }
    });
    
    my $o = __PACKAGE__->new(alias => $session_name, object => $async,
                             on_error => $user_error_callback);
    POE::Session->create(
        heap => $o,
        inline_states =>
            POE::Sugar::Attributes->inline_states(__PACKAGE__, $session_name)
    );
    $async->connect();
    return $o;
}

sub _single_dispatch_common {
    my ($result,$arg) = @_;
    my ($key) = keys %$result;
    my ($ret) = values %$result;
        
    if($arg->{callback}) {
        $arg->{callback}->($key, $ret, $arg->{arg});
    } else {
        $poe_kernel->post($arg->{session}, $arg->{state},
                          $key, $ret,$arg->{arg});
    }
}

sub _strop_common {
    my ($self,$command,$key,
        $value,$expiry,$cas,$cbparams) = @_;
    my @arry;
    
    if( $cbparams->{state} && (!$cbparams->{session}) ) {
        $cbparams->{session} = $_[SENDER];
    }
    
    unless($cbparams->{state} || $cbparams->{callback}) {
        die("Must have either target state or CODE reference for notification");
    }
    
    if($cbparams->{callback}) {
        unless(ref $cbparams->{callback} eq 'CODE') {
            die("Callback must be a CODE reference");
        }
    }
    
    arry_assign_i(@arry,
        REQIDX_KEY, $key,
        REQIDX_VALUE, $value,
        REQIDX_EXP, $expiry,
        REQIDX_CAS, $cas);
    
    $self->object->request(
        $command, REQTYPE_SINGLE,
        \&_single_dispatch_common, $cbparams, CBTYPE_COMPLETION,
        \@arry
    );
}


sub _numop_common {
    my ($self,$key,$delta,$initial,$expiry,$cbparams) = @_;
    my @arry;
    arry_assign_i(@arry,
        REQIDX_KEY, $key,
        REQIDX_ARITH_DELTA, $delta,
        REQIDX_ARITH_INITIAL, $initial,
        REQIDX_EXP, $expiry);
    $self->object->request(
        PLCBA_CMD_ARITHMETIC, REQTYPE_SINGLE,
        \&_single_dispatch_common, $cbparams, CBTYPE_COMPLETION,
        \@arry
    );
}

my %_state_map = (
    add         => PLCBA_CMD_ADD,
    replace     => PLCBA_CMD_REPLACE,
    append      => PLCBA_CMD_APPEND,
    prepend     => PLCBA_CMD_PREPEND,
    set         => PLCBA_CMD_SET
);

sub _set_common :Event(add, replace, append, prepend, set)
{
    my ($op_params,$cb_params) = @_[ARG0,ARG1];
    my ($key,$value,$expiry,$cas);
    my $command;
    
    if($_[STATE] eq 'cas') {
        $command = PLCBA_CMD_SET;
        ($key,$value,$cas,$expiry) = @$op_params;
    } else {
        $command = $_state_map{$_[STATE]};
        ($key,$value,$expiry) = @$op_params;
    }
    
    $_[HEAP]->_strop_common($command,
                            $key, $value, $expiry, $cas,
                            $cb_params);
}

sub get :Event {
    my ($key,$cbparams) = @_[ARG0,ARG1];
    if(ref $key) {
        $key = $key->[0];
    }
    $_[HEAP]->_strop_common(
        PLCBA_CMD_GET, $key, undef, undef, undef, $cbparams);
}

sub arithmetic :Event {
    my ($op_params,$cb_params) = @_[ARG0, ARG1];
    my ($key,$delta,$initial,$expiry) = @$op_params;
    $_[HEAP]->_numop_common($key, $delta, $initial, $expiry, $cb_params);
}

sub _arith_basic :Event(incr, decr) {
    my ($op_params,$cb_params) = @_[ARG0..ARG1];
    my ($key,$delta,$expiry);
    if(!ref $op_params) {
        $delta = 1;
        $key = $op_params;
    } else {
        ($key,$delta,$expiry) = @$op_params;
    }
    if($_[STATE] eq 'decr') {
        $delta = (-$delta);
    }
    $_[HEAP]->_numop_common($key, $delta, undef, $expiry, $cb_params);
}

sub _keyop :Event(touch, remove)
{
    my ($op_params, $cb_params) = @_[ARG0,ARG1];
    my ($key,$expiry,$cas);
    my $command;
    
    if($_[STATE] eq 'touch') {
        ($key,$expiry) = @$op_params;
        $command = PLCBA_CMD_TOUCH;
    } else {
        ($key,$cas) = @$op_params;
        $command = PLCBA_CMD_REMOVE;
    }
    
    my @arry;
    arry_assign_i(@arry,
        REQIDX_KEY, $key,
        REQIDX_EXP, $expiry,
        REQIDX_CAS, $cas);
    $_[HEAP]->object->request(
        $command, REQTYPE_SINGLE,
        \&_single_dispatch_common, $cb_params, CBTYPE_COMPLETION,
        \@arry
    );
}

1;
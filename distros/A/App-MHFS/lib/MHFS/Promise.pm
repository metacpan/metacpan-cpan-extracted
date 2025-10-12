package MHFS::Promise v0.7.0;
use 5.014;
use strict; use warnings;
use feature 'say';
use Feature::Compat::Try;
use constant {
    MHFS_PROMISE_PENDING => 0,
    MHFS_PROMISE_SUCCESS => 1,
    MHFS_PROMISE_FAILURE => 2,
    MHFS_PROMISE_ADOPT   => 3
};

sub finale {
    my ($self) = @_;
    my $success = $self->{state} == MHFS_PROMISE_SUCCESS;
    foreach my $item (@{$self->{waiters}}) {
        $self->handle($item);
    }
    $self->{waiters} = [];
}

sub _new {
    my ($class, $evp) = @_;
    my %self = ( 'evp' => $evp, 'waiters' => [], 'state' => MHFS_PROMISE_PENDING);
    bless \%self, $class;
    $self{fulfill} = sub {
        my $value = $_[0];
        if(ref($value) eq $class) {
            $self{state} = MHFS_PROMISE_ADOPT;
            say "adopting promise";
        } else {
            $self{state} = MHFS_PROMISE_SUCCESS;
            #say "resolved with " . ($_[0] // 'undef');
        }
        $self{end_value} = $_[0];
        finale(\%self);
    };
    $self{reject} = sub {
        $self{state} = MHFS_PROMISE_FAILURE;
        $self{end_value} = $_[0];
        finale(\%self);
    };
    return \%self;
}

sub new {
    my ($class, $evp, $cb) = @_;
    my $self = _new(@_);
    $cb->($self->{fulfill}, $self->{reject});
    return $self;
}

sub handleResolved {
    my ($self, $deferred) = @_;
    $self->{evp}->add_timer(0, 0, sub {
        my $success = $self->{state} == MHFS_PROMISE_SUCCESS;
        my $value = $self->{end_value};
        if($success && $deferred->{onFulfilled}) {
            try {
                $value = $deferred->{onFulfilled}($value);
            } catch ($e) {
                $success = 0;
                $value = $e;
            }
        } elsif(!$success && $deferred->{onRejected}) {
            try {
                $value = $deferred->{onRejected}->($value);
                $success = 1;
            } catch ($e) {
                $value = $e;
            }
        }
        if($success) {
            $deferred->{promise}{fulfill}->($value);
        } else {
            $deferred->{promise}{reject}->($value);
        }
        return undef;
    });
}

sub handle {
    my ($self, $deferred) = @_;
    while($self->{state} == MHFS_PROMISE_ADOPT) {
        $self = $self->{end_value};
    }
    if($self->{state} == MHFS_PROMISE_PENDING) {
        push(@{$self->{'waiters'}}, $deferred);
    } else {
        $self->handleResolved($deferred);
    }
}

sub then {
    my ($self, $onFulfilled, $onRejected) = @_;
    my $promise = MHFS::Promise->_new($self->{evp});
    my %handler = ( 'promise' => $promise, onFulfilled => $onFulfilled, onRejected => $onRejected);
    $self->handle(\%handler);
    return $promise;
}

1;

use utf8;
use strict;
use warnings;

package DR::Tarantool::MsgPack::CoroClient;
use base qw(DR::Tarantool::MsgPack::AsyncClient);
use AnyEvent;
use Carp;
use Data::Dumper;
use Coro;

sub connect {
    my ($class, %opts) = @_;
    my $cv = AE::cv;

    $opts{raise_error} = 1 unless exists $opts{raise_error};

    $class->SUPER::connect(%opts, sub { $cv->send(@_) });
    my ($self) = $cv->recv;
    croak $self unless ref $self;

    $self->{raise_error} = $opts{raise_error};
    return $self;
}

sub ping {
    my ($self) = @_;
    $self->SUPER::ping( Coro::rouse_cb );
    my ($status, $tuple, $code) = Coro::rouse_wait;
    return 1 if $status and $status eq 'ok';
    return 0;
}


for my $method (qw(insert replace select update delete call_lua)) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$method" } = sub {
        my ($self, @args) = @_;
        my $m = "SUPER::$method";
        $self->$m(@args, Coro::rouse_cb);
        my @res = Coro::rouse_wait;

        return $res[1] if $res[0] eq 'ok';
        
        return undef unless $self->{raise_error};
        croak  sprintf "%s: %s",
            defined($res[1])? $res[1] : 'unknown',
            $res[2]
        ;
    };
}


1;

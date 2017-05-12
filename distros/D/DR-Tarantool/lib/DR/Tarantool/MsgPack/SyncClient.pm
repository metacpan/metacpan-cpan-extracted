use utf8;
use strict;
use warnings;

package DR::Tarantool::MsgPack::SyncClient;
use base qw(DR::Tarantool::MsgPack::AsyncClient);
use AnyEvent;
use Carp;
use Data::Dumper;

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
    my $cv = AE::cv;
    $self->SUPER::ping( sub { $cv->send(@_) } );
    my ($status, $tuple, $code) = $cv->recv;
    return 1 if $status and $status eq 'ok';
    return 0;
}


for my $method (qw(insert replace select update delete call_lua)) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$method" } = sub {
        my ($self, @args) = @_;
        my $cv = AE::cv;
        my $m = "SUPER::$method";
        $self->$m(@args, sub { $cv->send(@_) });
        my @res = $cv->recv;

        return $res[1] if $res[0] eq 'ok';
        
        return undef unless $self->{raise_error};
        croak  sprintf "%s: %s",
            defined($res[1])? $res[1] : 'unknown',
            $res[2]
        ;
    };
}


1;

package Audio::XMMSClient;

use strict;
use warnings;
use Carp;
use IO::Handle;
use IO::Select;
use Audio::XMMSClient::Collection;

our $VERSION = 0.03;
our @ISA;

eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    1;
} or do {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    bootstrap Audio::XMMSClient $VERSION;
};

sub loop {
    my ($self) = @_;

    my $fd = IO::Handle->new_from_fd( $self->io_fd_get, 'r+' );
    $self->{do_loop} = 1;

    pipe my $r, my $w;
    $self->{wakeup} = $w;

    my $rin = IO::Select->new( $fd, $r );
    my $ein = IO::Select->new( $fd     );
    my $win;

    while ($self->{do_loop}) {

        if ($self->io_want_out) {
            $win = IO::Select->new( $fd );
        }
        else {
            $win = undef;
        }

        my ($i, $o, $e) = IO::Select->select( $rin, $win, $ein );

        if (ref $i && @$i && $i->[0] == $fd) {
            $self->io_in_handle;
        }

        if (ref $o && @$o && $o->[0] == $fd) {
            $self->io_out_handle;
        }

        if (ref $e && @$e && $e->[0] == $fd) {
            $self->disconnect;
            $self->{do_loop} = 0;
        }
    }
}

sub quit_loop {
    my ($self) = @_;

    $self->{do_loop} = 0;
    $self->{wakeup}->print('42');
}

sub request {
    my $self = shift;
    my $func = shift;

    my $user_data = pop;
    my $callback  = pop;

    if (!$self->can($func)) {
        Carp::croak( "Invalid request name `${func}' given" );
    }

    my $result = $self->$func( @_ );
    $result->notifier_set($callback, $user_data);

    return $result;
}

1;

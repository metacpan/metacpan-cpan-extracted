package Argon::Dispatcher;

use Moo;
use MooX::HandlesVia;
use Types::Standard qw(-types);
use Carp;

extends 'Argon::Service';

#-------------------------------------------------------------------------------
# Maps an $Argon::CMD_* constant to a code ref which handles it. Method calls
# (closing over $self) should use Argon::K to create the callback.
#
# Integrating classes use 'responds_to' to configure their request handling:
#
#   $self->responds_to($CMD_QUEUE, K('handler_sub', $self));
#-------------------------------------------------------------------------------
has _dispatch => (
    is          => 'ro',
    isa         => Map[Int, CodeRef],
    init_arg    => undef,
    default     => sub {{}},
    handles_via => 'Hash',
    handles     => {
        respond_to   => 'set',
        get_callback => 'get',
        responds_to  => 'exists',
    }
);

#-------------------------------------------------------------------------------
# Evaluates the configured callback for a message's command. If none is
# configured, throws an error.
#-------------------------------------------------------------------------------
sub dispatch {
    my $self = shift;
    my $msg  = shift;
    my $cmd  = $msg->cmd;
    croak "command not handled: $cmd" unless $self->responds_to($cmd);
    return $self->get_callback($cmd)->($msg, @_);
}

1;

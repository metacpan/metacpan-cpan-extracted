package Argon::Message;

use strict;
use warnings;

use Carp;
use Storable       qw();
use Coro::Storable qw(nfreeze thaw);
use Data::UUID;
use MIME::Base64   qw(encode_base64 decode_base64);
use Argon          qw(:priorities);

use fields qw(
    id
    cmd
    pri
    payload
    key
);

#-------------------------------------------------------------------------------
# Creates a new message.
#-------------------------------------------------------------------------------
sub new {
    my ($class, %param) = @_;
    defined $param{cmd} || croak 'expected parameter "cmd"';
    my $self = fields::new($class);
    $self->{id}  = $param{id}  || Data::UUID->new->create_str;
    $self->{cmd} = $param{cmd};
    $self->{pri} = $param{pri} || $PRI_NORMAL;
    $self->{key} = $param{key} || 'OPEN';
    $self->{payload} = $param{payload};
    return $self;
}

#-------------------------------------------------------------------------------
# Accessors and comparison method
#-------------------------------------------------------------------------------
sub cmp     { $_[0]->{pri} <=> $_[1]->{pri} }
sub id      { $_[0]->{id}      }
sub cmd     { $_[0]->{cmd}     }
sub pri     { $_[0]->{pri}     }
sub key     { $_[0]->{key}     }
sub payload { $_[0]->{payload} }

#-------------------------------------------------------------------------------
# Encodes a message into a line of ASCII (base64-encoded) which can be
# transmitted on the line.
#-------------------------------------------------------------------------------
sub encode {
    my $self = shift;

    my $data = do {
        no warnings 'once';
        local $Storable::Deparse    = 1;
        local $Storable::forgive_me = 1;

        defined $self->{payload}
            ? encode_base64(nfreeze([$self->{payload}]), '')
            : '-';
    };

    my $line = join(
        $Argon::MSG_SEPARATOR,
        $self->{id},
        $self->{cmd},
        $self->{pri},
        $self->{key},
        $data,
    );

    return $line;
}

#-------------------------------------------------------------------------------
# Decodes a line of data and returns a new Argon::Message object.
#-------------------------------------------------------------------------------
sub decode {
    my ($class, $line) = @_;
    my ($id, $cmd, $pri, $key, $payload) = split $Argon::MSG_SEPARATOR, $line;

    croak 'incomplete message'
        unless defined $id
            && defined $cmd
            && defined $pri
            && defined $key;

    if ($payload eq '-') {
        undef $payload;
    } else {
        no warnings 'once';
        local $Storable::Eval = 1;
        $payload = thaw(decode_base64($payload))->[0];
    }

    return $class->new(
        id      => $id,
        cmd     => $cmd,
        pri     => $pri,
        key     => $key,
        payload => $payload,
    );
}

#-------------------------------------------------------------------------------
# Creates a new Argon::Message object replying to this instance. Named
# parameters passed in are forwarded to the constructor to override those
# values in this instance.
#-------------------------------------------------------------------------------
sub reply {
    my ($self, %param) = @_;
    return $self->new(%$self, %param)
}

1;

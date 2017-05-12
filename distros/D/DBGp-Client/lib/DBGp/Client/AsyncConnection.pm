package DBGp::Client::AsyncConnection;

use strict;
use warnings;

use DBGp::Client::AsyncStream;
use DBGp::Client::Parser;
use Scalar::Util;

sub new {
    my ($class, %args) = @_;
    my $stream = DBGp::Client::AsyncStream->new(socket => $args{socket});

    my $self = my $weak_self = bless {
        stream          => $stream,
        sequence        => 0,
        init            => undef,
        commands        => {},
        on_stream       => undef,
        on_notification => undef,
    }, $class;
    Scalar::Util::weaken($weak_self);
    $stream->on_line(sub { $weak_self->_receive_line(@_) });

    return $self;
}

sub init { $_[0]->{init} }

sub send_command {
    my ($self, $callback, $command, @args) = @_;
    my $seq_id = ++$self->{sequence};

    $self->{commands}{$seq_id} = $callback;
    $self->{stream}->put_line($command, '-i', $seq_id, @args);
}

sub add_data { $_[0]->{stream}->add_data($_[1]) }

sub closed {
    my ($self) = @_;

    for my $transaction_id (keys %{$self->{commands}}) {
        my $error = bless {
            transaction_id  => $transaction_id,
            code            => 999,
            apperr          => 1,
            message         => "Broken connection",
        }, 'DBGp::Client::Response::InternalError';

        eval {
            delete($self->{commands}{$transaction_id})->($error);
        };
    }
}

sub _receive_line {
    my ($self, $line) = @_;

    if (!$self->{init}) {
        $self->{init} = DBGp::Client::Parser::parse($line);
    } else {
        my $res = DBGp::Client::Parser::parse($line);

        if ($res->is_oob) {
            if ($res->is_stream && $self->{on_stream}) {
                $self->{on_stream}->($res);
            } elsif ($res->is_notification && $self->{on_notification}) {
                $self->{on_notification}->($res);
            }
        } else {
            my $callback = delete $self->{commands}{$res->transaction_id};

            die 'Mismatched transaction IDs: ', $res->transaction_id
                unless $callback;

            $callback->($res);
        }
    }
}

sub on_stream { $_[0]->{on_stream} = $_[1] }
sub on_notification { $_[0]->{on_notification} = $_[1] }

1;

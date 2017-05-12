package DBIx::Aurora::Cluster;
use strict;
use warnings;
use Carp;
use Time::HiRes;
use List::Util 'shuffle';
use DBIx::Aurora::Instance;
use constant {
    map { ($_ => $_) } qw(
        ERROR_TYPE_CONNECT_WRITER
        ERROR_TYPE_CONNECT_READER
    )
};

sub new {
    my ($class, $instances, $opts) = @_;
    my $self = bless {
        force_reader_only  => 0,
        reconnect_interval => 5,
        logger => sub {},
        %$opts,
        instances => { },
    }, $class;

    for (my $i = 0; $i < @$instances; $i++) {
        my $instance = $instances->[$i];
        my $aurora_instance = DBIx::Aurora::Instance->new(@$instance);
        $self->{instances}{$i} = {
            instance => $aurora_instance,
        };
    }

    $self;
}

sub log {
    my ($self, $error_type, $message, $exception) = @_;
    $self->{logger}->($error_type, $message, $exception);
}

sub aurora_instances { map { $_->{instance} } values %{$_[0]->{instances}} }

sub _update_connectivity {
    my ($self, $instance) = @_;

    if ($instance->connected_at + $self->{reconnect_interval} < Time::HiRes::time) {
        $instance->disconnect;
        $instance->handler;
    }
}

sub writer {
    my ($self, $callback) = @_;
    my $wantarray = wantarray;

    my @maybe_readers = grep { $_->maybe_reader } $self->aurora_instances;
    my @maybe_writers = grep { $_->maybe_writer } $self->aurora_instances;

    my $instance;
    for my $i (shuffle(@maybe_writers), shuffle(@maybe_readers)) {
        next if $i->is_unreachable;

        eval { $self->_update_connectivity($i) };
        if (my $e = $@) {
            $self->log(ERROR_TYPE_CONNECT_WRITER, "Aurora Writer connection error", $e);

            if (ref $e && $e->isa('DBIx::Aurora::Instance::Exception::Connectivity')) {
                next; # connectivity issue, try next reader
            } else {
                Carp::croak($e);
            }
        } else {
            if ($i->is_writer) {
                $instance = $i;
                last;
            } else {
                next;
            }
        }
    }

    unless ($instance) {
        Carp::croak "No writer found";
    }

    my @ret = eval {
        $wantarray
            ?        $instance->handler->txn($callback)
            : scalar $instance->handler->txn($callback);
    };
    if (my $e = $@) {
        Carp::croak($e);
    }

    return $wantarray ? @ret : $ret[0];
}

sub reader {
    my ($self, $callback) = @_;
    my $wantarray = wantarray;

    my @is_reader     = grep { $_->is_reader    } $self->aurora_instances;
    my @maybe_readers = grep { $_->maybe_reader } $self->aurora_instances;
    my @maybe_writers = grep { $_->maybe_writer } $self->aurora_instances;

    my $instance;
    for my $i (shuffle(@is_reader), shuffle(@maybe_readers), shuffle(@maybe_writers)) {
        next if $i->is_unreachable;

        eval { $self->_update_connectivity($i) };
        if (my $e = $@) {
            $self->log(ERROR_TYPE_CONNECT_READER, "Aurora Reader connection error", $e);
            if (ref $e && $e->isa('DBIx::Aurora::Instance::Exception::Connectivity')) {
                next; # connectivity issue, try next reader
            } else {
                Carp::croak($e);
            }
        } elsif ($i->is_reader) {
            $instance = $i;
            last;
        } else {
            next; # it's writer
        }
    }

    if (not $instance) {
        if ($self->{force_reader_only}) {
            Carp::croak "No reader found";
        } else {
            return $self->writer($callback); # fallback to writer
        }
    }

    my @ret = eval {
        $wantarray
            ?        $instance->handler->txn($callback)
            : scalar $instance->handler->txn($callback);
    };
    if (my $e = $@) {
        Carp::croak($e);
    }

    return $wantarray ? @ret : $ret[0];
}

sub disconnect_all {
    my $self = shift;
    for my $instance ($self->aurora_instances) {
        $instance && $instance->disconnect;
    }
}

sub disconnect_writer {
    my $self = shift;
    for my $instance ($self->aurora_instances) {
        $instance && $instance->maybe_writer && $instance->disconnect;
    }
}

sub disconnect_reader {
    my $self = shift;
    for my $instance ($self->aurora_instances) {
        $instance && $instance->maybe_reader && $instance->disconnect;
    }
}

sub DESTROY { $_[0]->disconnect_all }

1;
__END__

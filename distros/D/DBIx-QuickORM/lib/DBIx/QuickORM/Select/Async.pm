package DBIx::QuickORM::Select::Async;
use strict;
use warnings;

our $VERSION = '0.000004';

use Carp qw/croak/;

use parent 'DBIx::QuickORM::Select';
use DBIx::QuickORM::Util::HashBase qw{
    +ready
    +started
    +result
};

sub start {
    my $self = shift;

    croak "Async query already started" if $self->{+STARTED};

    $self->{+STARTED} = $self->{+SOURCE}->do_select($self->params, async => $self);

    return $self;
}

sub started { $_[0]->{+STARTED} ? $_[0] : undef }

sub sth { $_[0]->{+STARTED} ? $_[0]->{+STARTED}->{sth} : croak 'Async query has not been started (did you forget to call $s->start?)' }

sub ready {
    my $self = shift;
    return $self if defined $self->{+READY};

    my $started = $self->{+STARTED} or croak 'Async query has not been started (did you forget to call $s->start?)';

    return undef unless $started->{ready}->();

    $self->{+READY} = 1;
    return $self;
}

sub cancel { $_[0]->discard }

sub result {
    my $self = shift;
    return $self->{+RESULT} if defined $self->{+RESULT};

    $self->wait();

    return $self->{+RESULT};
}

sub _rows {
    my $self = shift;
    return $self->{+ROWS} if $self->{+ROWS};

    $self->wait();

    return $self->{+ROWS};
}

sub wait {
    my $self = shift;

    return if exists $self->{+RESULT};
    return if exists $self->{+ROWS};

    my $started = $self->{+STARTED} or croak 'Async query has not been started (did you forget to call $s->start?)';

    $self->{+READY}  = 1;
    $self->{+RESULT} = $started->{result}->();
    $self->{+ROWS}   = $started->{fetch}->();

    $self->connection->async_stop($self);

    return $self;
}

sub count { @{$_[0]->_rows} }

sub discard {
    my $self = shift;

    my $done = 0;
    for my $field (ROWS(), READY(), RESULT()) {
        $done = 1 if delete $self->{$field};
    }

    if (my $started = delete $self->{+STARTED}) {
        $started->{cancel}->() unless $done;
    }

    $self->connection->async_stop($self);

    return $self;
}

1;

package DBIx::QuickORM::DB;
use strict;
use warnings;

our $VERSION = '0.000011';

use Carp qw/croak confess/;
use Scalar::Util qw/blessed/;

use DBIx::QuickORM::Util::HashBase qw{
    <name
    +connect
    <attributes
    +db_name
    +dsn
    <host
    <port
    <socket
    <user
    <pass
    <created
    <compiled
    <dialect
    <dbi_driver
};

sub db_name { $_[0]->{+DB_NAME} // $_[0]->{+NAME} }

sub init {
    my $self = shift;

    croak "'dialect' is a required attribute" unless $self->{+DIALECT};

    delete $self->{+NAME} unless defined $self->{+NAME};

    $self->{+ATTRIBUTES} //= {};
    $self->{+ATTRIBUTES}->{RaiseError}          //= 1;
    $self->{+ATTRIBUTES}->{PrintError}          //= 1;
    $self->{+ATTRIBUTES}->{AutoCommit}          //= 1;
    $self->{+ATTRIBUTES}->{AutoInactiveDestroy} //= 1;

    croak "Cannot provide both a socket and a host" if $self->{+SOCKET} && $self->{+HOST};
}

sub dsn {
    my $self = shift;
    return $self->{+DSN} if $self->{+DSN};
    return $self->{+DSN} = $self->{+DIALECT}->dsn($self);
}

sub new_dbh {
    my $self = shift;
    my (%params) = @_;

    my $attrs = $self->attributes;

    my $dbh;
    eval {
        if ($self->{+CONNECT}) {
            $dbh = $self->{+CONNECT}->();
        }
        else {
            require DBI;
            $dbh = DBI->connect($self->dsn, $self->user, $self->pass, $self->attributes);
        }

        1;
    } or confess $@;

    $dbh->{AutoInactiveDestroy} = 1 if $attrs->{AutoInactiveDestroy};

    return $dbh;
}

1;

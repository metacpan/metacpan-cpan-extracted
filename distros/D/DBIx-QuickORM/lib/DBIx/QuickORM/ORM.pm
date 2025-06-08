package DBIx::QuickORM::ORM;
use strict;
use warnings;

our $VERSION = '0.000011';

use Carp qw/croak/;

use DBIx::QuickORM::Connection;

use DBIx::QuickORM::Util::HashBase qw{
    <name
    <db
    <schema
    <autofill
    <row_class
    <created
    <compiled
    cache_class
    <default_handle_class

    +connection
};

sub init {
    my $self = shift;

    delete $self->{+NAME} unless defined $self->{+NAME};

    my $db = $self->{+DB} or croak "'db' is a required attribute";

    croak "You must either provide the 'schema' attribute or enable 'autofill'"
        unless $self->{+SCHEMA} || $self->{+AUTOFILL};
}

sub connect {
    my $self = shift;

    my %params = (orm => $self);
    $params{cache} = $self->{+CACHE_CLASS}->new() if $self->{+CACHE_CLASS};

    $params{+DEFAULT_HANDLE_CLASS} = $self->{+DEFAULT_HANDLE_CLASS};

    return DBIx::QuickORM::Connection->new(%params);
}

sub disconnect {
    my $self = shift;
    delete $self->{+CONNECTION};
}

sub reconnect {
    my $self = shift;
    $self->disconnect;
    return $self->connection;
}

sub connection {
    my $self = shift;
    return $self->{+CONNECTION} //= $self->connect;
}

sub handle {
    my $self = shift;
    return $self->connection->handle(@_);
}

1;

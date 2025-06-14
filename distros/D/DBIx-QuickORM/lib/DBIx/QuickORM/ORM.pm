package DBIx::QuickORM::ORM;
use strict;
use warnings;

our $VERSION = '0.000015';

use Carp qw/croak/;

use DBIx::QuickORM::Connection;

use DBIx::QuickORM::Util::HashBase qw{
    <name
    +db
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

    croak "You must either provide the 'schema' attribute or enable 'autofill'"
        unless $self->{+SCHEMA} || $self->{+AUTOFILL};
}

sub db {
    my $self = shift;

    if (@_) {
        croak "'db' has already been set" if $self->{+DB};
        croak "Too many arguments" if @_ > 1;
        ($self->{+DB}) = @_;
    }

    return $self->{+DB} // croak "'db' has not been set";
}

sub connect {
    my $self = shift;

    croak "'db' has not been set" unless $self->{+DB};

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

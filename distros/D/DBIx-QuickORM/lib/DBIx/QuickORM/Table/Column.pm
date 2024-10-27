package DBIx::QuickORM::Table::Column;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/croak confess/;
use Role::Tiny::With qw/with/;

use DBIx::QuickORM::Util::HashBase qw{
    <conflate
    <default
    <name
    <omit
    <primary_key
    <unique
    <order
    <nullable
    <serial
    +sql_spec
    <created
};

with 'DBIx::QuickORM::Role::HasSQLSpec';

sub init {
    my $self = shift;

    croak "The 'name' field is required"     unless $self->{+NAME};
    croak "Column must have an order number" unless $self->{+ORDER};

    if (my $conflate = $self->{+CONFLATE}) {
        if (ref($conflate) eq 'HASH') { # unblessed hash
            confess "No inflate callback was provided for conflation" unless $conflate->{inflate};
            confess "No deflate callback was provided for conflation" unless $conflate->{deflate};

            require DBIx::QuickORM::Conflator;
            $self->{+CONFLATE} = DBIx::QuickORM::Conflator->new(%$conflate);
        }
    }
}

sub compare_type {
    my $self = shift;
    my ($db_type) = @_;

    return 'number' if $self->{+SERIAL};

    my $c = $self->{+CONFLATE};
    $c = undef unless $c && $c->can('qorm_compare_type');

    for my $type ($self->sql_type, $db_type) {
        next unless $type;

        my $out;
        $out = $c->qorm_compare_type($type) if $c;
        return $out if $out;

        return 'number' if $type =~ m/(int|double|bit|bool|dec|float|real|serial|numeric)/i;
    }

    return 'string';
}

sub sql_type {
    my $self = shift;
    my (@dbs) = @_;

    my $spec = $self->{+SQL_SPEC} or return;
    return $spec->get_spec(type => @dbs);
}

sub merge {
    my $self = shift;
    my ($other, %params) = @_;

    $params{+SQL_SPEC} //= $self->{+SQL_SPEC}->merge($other->{+SQL_SPEC});

    return ref($self)->new(%$self, %params);
}

sub clone {
    my $self   = shift;
    my %params = @_;

    $params{+SQL_SPEC} //= $self->{+SQL_SPEC}->clone();

    return ref($self)->new(%$self, %params);
}

1;

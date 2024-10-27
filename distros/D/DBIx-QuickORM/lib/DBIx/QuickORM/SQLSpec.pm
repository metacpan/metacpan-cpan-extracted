package DBIx::QuickORM::SQLSpec;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/confess/;

use DBIx::QuickORM::SQLSpec::Params;

use DBIx::QuickORM::Util qw/merge_hash_of_objs/;

use DBIx::QuickORM::Util::HashBase qw{
    <global
    <overrides
};

sub init {
    my $self = shift;

    $self->{+GLOBAL}    //= DBIx::QuickORM::SQLSpec::Params->new;
    $self->{+OVERRIDES} //= {};

    for my $key (keys %$self) {
        next if $key eq GLOBAL;
        next if $key eq OVERRIDES;

        my $val = delete $self->{$key};
        my $ref = ref($val);

        if ($ref && $ref eq 'HASH') {
            $self->{+OVERRIDES}->{$key} = DBIx::QuickORM::SQLSpec::Params->new(%$val);
        }
        elsif (!$ref || $ref eq 'ARRAY' || $ref eq 'SCALAR') {
            $self->{+GLOBAL}->{$key} = $val;
        }
        else {
            confess "Invalid parameter value for key $key: $val";
        }
    }
}

sub get_spec {
    my $self = shift;
    my ($spec, @dbs) = @_;

    my $global = $self->{+GLOBAL};

    for my $db (@dbs) {
        if (my $dbset = $self->{+OVERRIDES}->{$db}) {
            return $dbset->param($spec) // $global->param($spec);
        }
    }

    return $global->param($spec);
}

sub clone {
    my $self = shift;
    my %params = @_;

    $params{+GLOBAL}    //= $self->{+GLOBAL}->clone;
    $params{+OVERRIDES} //= {map { ($_ => $self->{+OVERRIDES}->{$_}->clone) } keys %{$self->{+OVERRIDES}}};

    return ref($self)->new(%params);
}

sub merge {
    my $self = shift;
    my ($other, $params) = @_;

    $self->clone(
        GLOBAL()    => $self->{+GLOBAL}->merge($other->{+GLOBAL}),
        OVERRIDES() => merge_hash_of_objs($self->{+OVERRIDES}, $other->{+OVERRIDES}),
    );
}

1;

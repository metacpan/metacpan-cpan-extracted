package DBIx::QuickORM::Join;
use strict;
use warnings;

our $VERSION = '0.000013';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Sub::Util qw/set_subname/;
use DBIx::QuickORM::Join::Row;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Source';
with 'DBIx::QuickORM::Role::Linked';

use DBIx::QuickORM::Util::HashBase qw{
    <schema
    <primary_source
    <join_as
    <row_class

    <order
    <lookup
    <components
};

sub primary_key     { }
sub fields_to_omit  { }
sub source_orm_name   { 'JOIN' }
sub fields_list_all { croak "Not Supported" }

sub init {
    my $self = shift;
    croak "'schema' is required"         unless $self->{+SCHEMA};
    croak "'primary_source' is required" unless $self->{+PRIMARY_SOURCE};

    $self->{+JOIN_AS} = 'a';

    $self->{+ORDER}      //= [];
    $self->{+LOOKUP}     //= {};
    $self->{+COMPONENTS} //= {};

    my $first = $self->{+JOIN_AS}++;
    push @{$self->{+ORDER}}                                            => $first;
    push @{$self->{+LOOKUP}->{$self->{+PRIMARY_SOURCE}->source_db_moniker}} => $first;
    $self->{+COMPONENTS}->{$first} = {table => $self->{+PRIMARY_SOURCE}, as => $first};

    $self->{+ROW_CLASS} //= 'DBIx::QuickORM::Join::Row';
}

sub fracture {
    my $self = shift;
    my ($in) = @_;

    my $out = [];

    for my $as (@{$self->{+ORDER}}) {
        my $comp = $self->{+COMPONENTS}->{$as};

        my $not_null = 0;
        my $link     = $comp->{link};
        my $table    = $comp->{table};
        my $data     = {map { $not_null ||= defined($in->{$_}); m/^\Q$as\E\.(.+)$/; ($1 => $in->{$_}) } grep { m/^\Q$as\E\./ } keys %$in};

        next unless $not_null;
        push @$out => {source => $table, data => $data, as => $as, link => $link};
    }

    return $out;
}

sub clone {
    my $self   = shift;
    my %params = @_;

    my $class = blessed($self);

    return bless(
        {
            %$self,
            ORDER()      => [@{$self->{+ORDER}}],
            LOOKUP()     => {%{$self->{+LOOKUP}}},
            COMPONENTS() => {%{$self->{+COMPONENTS}}},
            %params,
        },
        $class,
    );
}

sub source_db_moniker {
    my $self = shift;

    my $lookup = $self->{+LOOKUP};
    my $comps  = $self->{+COMPONENTS};

    my $out;
    for my $as (@{$self->{+ORDER}}) {
        my $comp  = $comps->{$as} or die "No alias '$as'";
        my $link  = $comp->{link};
        my $from  = $comp->{from};
        my $table = $comp->{table};
        my $type  = $comp->{type} // "";

        if ($link) {
            my $lc = $link->local_columns;
            my $oc = $link->other_columns;

            my @cols;
            for (my $i = 0; $i < @$lc; $i++) {
                push @cols => "$as.$lc->[$i] = $from.$oc->[$i]";
            }

            $out .= $type =~ m/join/i ? " $type " : " $type JOIN ";
            $out .= $table->source_db_moniker . " AS $as ON (" . join(' AND ' => @cols) . ")";
        }
        else {
            $out = $table->source_db_moniker . " AS $as";
        }
    }

    return \$out;
}

sub _field_source {
    my $self = shift;
    my ($proto, %params) = @_;
    my ($field, $from) = reverse split /\./, $proto;

    if ($from) {
        my $c = $self->{+COMPONENTS}->{$from} or croak "'$from' is not an alias in this join";
        my $t = $c->{table};
        return ($from, $t, $field);
    }

    for my $alias (@{$self->{+ORDER}}) {
        my $c = $self->{+COMPONENTS}->{$from};
        my $t = $c->{table};
        next unless $t->has_field($field);
        return ($from, $t, $field);
    }

    return undef if $params{no_fatal};
    croak "This join does not have a '$field' field";
}

sub field_type {
    my $self = shift;
    my ($proto) = @_;
    my ($from, $t, $field) = $self->_field_source($proto);
    return $t->field_type($field);
}

sub field_affinity {
    my $self = shift;
    my ($proto, $dialect) = @_;
    my ($from, $t, $field) = $self->_field_source($proto);
    return $t->field_affinity($field, $dialect);
}

sub has_field {
    my $self = shift;
    my ($proto) = @_;
    my ($from, $t, $field) = $self->_field_source($proto, no_fatal => 1);
    return $t->has_field($field);
}

sub fields_to_fetch {
    my $self = shift;

    my @fields;

    for my $as (@{$self->{+ORDER}}) {
        my $c = $self->{+COMPONENTS}->{$as};
        my $t = $c->{table};
        push @fields => map { qq{$as.$_ AS "$as.$_"} } @{$t->fields_to_fetch};
    }

    return join(', ' => @fields);
}

sub links {
    my $self = shift;

    my @out;

    for my $as (@{$self->{+ORDER}}) {
        my $table = $self->{+COMPONENTS}->{$as}->{table};
        push @out => @{$table->links};
    }

    return \@out;
}

sub from {
    my $self = shift;
    my ($from) = @_;

    if (my $comp = $self->{+COMPONENTS}->{$from}) {
        return $comp->{table};
    }

    if (my $as_set = $self->{+LOOKUP}->{$from}) {
        croak "Ambiguous table name '$from' which has been joined to multiple times. Select an alias: " . join(', ' => @$as_set)
            if @$as_set > 1;

        my ($as) = @$as_set;
        if (my $comp = $self->{+COMPONENTS}->{$as}) {
            return $comp->{table};
        }
    }

    croak "Unable to resolve '$from' it does not appear to be a table name or an alias";
}

sub _join_params {
    my $self = shift;

    return (link => $_[0]) if @_ == 1;
    return @_;
}

sub _join {
    my $self = shift;
    my %params = @_;

    $self = $self->clone;

    croak "$params{meth}() should not be called in void context" unless defined wantarray;

    my $as   = $params{as};
    my $link = $params{link};
    my $from = $params{from};
    my $type = $params{type};

    until ($as) {
        my $try = $self->{+JOIN_AS}++;
        next if $self->{+COMPONENTS}->{$try};
        $as = $try;
    }

    croak "A join has already been made using the identifier '$as'" if $self->{+COMPONENTS}->{$as};

    if ($from && !$self->{+COMPONENTS}->{$from}) {
        my $check = $self->{+LOOKUP}->{$from};
        croak "'$from' is not defined" unless $check && @$check;
        croak "'$from' source has multiple aliases: " . join(', ' => @$check) if @$check > 1;
        ($from) = @$check;
    }

    unless ($from) {
        my $lt = $link->local_table;
        if ($lt eq $self->{+PRIMARY_SOURCE}->name) {
            $from = $self->{+ORDER}->[0];
        }
        elsif (my $n = $self->{+LOOKUP}->{$lt}) {
            croak "Table '$lt' has been joined multiple times, you must specify which name to use in the join" if @$n > 1;
            $from = $n->[0];
        }
        else {
            croak "Table '$lt' is not yet in the join";
        }
    }

    push @{$self->{+ORDER}} => $as;

    push @{$self->{+LOOKUP}->{$link->other_table}} => $as;

    $self->{+COMPONENTS}->{$as} = {
        as    => $as,
        table => $self->schema->table($link->other_table),
        link  => $link,
        from  => $from,
        type  => $type,
    };

    return $self;
}

sub left_join {
    my $self = shift;
    my %params = $self->_join_params(@_);
    $params{type} = 'LEFT';
    return $self->_join(meth => 'left_join', %params);
}

sub right_join {
    my $self = shift;
    my %params = $self->_join_params(@_);
    $params{type} = 'RIGHT';
    return $self->_join(meth => 'right_join', %params);
}

sub inner_join {
    my $self = shift;
    my %params = $self->_join_params(@_);
    $params{type} = 'INNER';
    return $self->_join(meth => 'inner_join', %params);
}

{
    no warnings 'once';
    *join = set_subname 'join' => sub {
        my $self   = shift;
        my %params = $self->_join_params(@_);
        return $self->_join(meth => 'join', %params);
    };
}

1;

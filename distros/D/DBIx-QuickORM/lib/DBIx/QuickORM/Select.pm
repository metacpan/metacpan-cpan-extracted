package DBIx::QuickORM::Select;
use strict;
use warnings;

our $VERSION = '0.000002';

use Carp qw/croak confess/;
use Sub::Util qw/set_subname/;
use Test2::Util qw/CAN_REALLY_FORK/;
use Scalar::Util qw/blessed/;
use DBIx::QuickORM::Util qw/parse_hash_arg/;

use DBIx::QuickORM::Util::HashBase qw{
    <source
    <where
    <limit
    <order_by
    <prefetch
    +count
    +rows
    +index
    +params
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::SelectLike';
with 'DBIx::QuickORM::Role::HasORM';

sub init {
    my $self = shift;

    croak "'source' is a required attribute" unless $self->{+SOURCE};

    $self->{+INDEX} = 0;
}

sub reset   { $_[0]->{+INDEX} = 0; $_[0] }
sub discard { delete($_[0]->{+ROWS}); $_[0] }

sub busy { $_[0]->source->busy }

BEGIN {
    for my $attr_const (WHERE(), LIMIT(), ORDER_BY(), PREFETCH()) {
        my $attr = "$attr_const";

        my $set_meth     = "set_$attr";
        my $clear_meth   = "clear_$attr";
        my $with_meth    = "with_$attr";
        my $without_meth = "without_$attr";

        my $set = sub {
            my $self = shift;

            if (@_) {
                ($self->{$attr}) = @_;
            }
            else {
                delete $self->{$attr};
            }

            delete $self->{+PARAMS};

            $self->reset;
            $self->discard;

            return $self;
        };

        my $clear = sub {
            my $self = shift;

            delete $self->{$attr};
            delete $self->{+PARAMS};

            $self->reset;
            $self->discard;

            return $self;
        };

        my $with = sub {
            my $self = shift;
            return $self->clone->$set_meth(@_) if @_;
            return $self->clone->$clear_meth();
        };

        my $without = sub { $_[0]->clone->$clear_meth };

        no strict 'refs';
        no warnings 'once';

        *$set_meth     = set_subname($set_meth     => $set);
        *$clear_meth   = set_subname($clear_meth   => $clear);
        *$with_meth    = set_subname($with_meth    => $with);
        *$without_meth = set_subname($without_meth => $without);
    }
}

sub orm              { $_[0]->{+SOURCE}->orm }
sub find_or_insert   { shift->{+SOURCE}->find_or_insert(@_) }
sub insert           { shift->{+SOURCE}->insert(@_) }
sub insert_row       { shift->{+SOURCE}->insert_row(@_) }
sub update_or_insert { shift->{+SOURCE}->update_or_insert(@_) }
sub table            { shift->{+SOURCE}->table(@_) }
sub select           { shift->{+SOURCE}->select(@_) }

sub update { die "FIXME" }

sub params {
    my $self = shift;

    return $self->{+PARAMS} if $self->{+PARAMS};

    my %out = (
        WHERE() => $self->{+WHERE} // {},
    );

    $out{+LIMIT}    = $self->{+LIMIT}    if $self->{+LIMIT};
    $out{+ORDER_BY} = $self->{+ORDER_BY} if $self->{+ORDER_BY};
    $out{+PREFETCH} = $self->{+PREFETCH} if $self->{+PREFETCH};

    return $self->{+PARAMS} = \%out;
}

sub aggregate { confess "Not implemented" } # FIXME TODO

sub async {
    my $self = shift;
    croak "async() cannot be called in void context" unless defined(wantarray);
    croak "This database engine does not support async queries" unless $self->source->connection->supports_async;
    require DBIx::QuickORM::Select::Async;
    DBIx::QuickORM::Select::Async->copy($self);
}

sub aside {
    my $self = shift;
    croak "aside() cannot be called in void context" unless defined(wantarray);
    croak "This database engine does not support async queries" unless $self->source->connection->supports_async;
    require DBIx::QuickORM::Select::Aside;
    DBIx::QuickORM::Select::Aside->copy($self);
}

sub forked {
    my $self = shift;
    croak "forked() cannot be called in void context" unless defined(wantarray);
    croak "This sytem does not support true forking" unless CAN_REALLY_FORK;
    require DBIx::QuickORM::Select::Forked;
    DBIx::QuickORM::Select::Forked->copy($self);
}

sub shotgun {
    die "TODO";

    #Send multiple aside/forked queries and returns an iterator for results as they come in.
}

sub find {
    my $self = shift;

    return $self->and(@_)->find if @_;

    my $r = $self->_rows or return undef;
    return undef unless @$r;

    croak "Multiple rows returned for fetch/find operation" if @$r > 1;

    return $r->[0];
}

sub count {
    my $self = shift;

    if (my $rows = $self->{+ROWS}) {
        return scalar @$rows;
    }

    return $self->{+SOURCE}->count_select($self->params);
}

# This should return a new select that will find all the obejects of the
# relation associated with the objects of this select.
sub relations { die "FIXME" }

sub _rows {
    my $self = shift;
    return $self->{+ROWS} //= $self->{+SOURCE}->do_select($self->params);
}

sub all   { @{shift->_rows} }
sub any   { my $r = shift->_rows; return undef unless @$r; return $r->[0] }
sub first { my $r = shift->_rows; return undef unless @$r; return $r->[0] }
sub last  { my $r = shift->_rows; return undef unless @$r; return $r->[-1] }

sub next {
    my $self = shift;
    my $i = $self->{+INDEX}++;
    my $rows = $self->_rows;
    return if $i > @$rows;
    return $rows->[$i];
}

sub previous {
    my $self = shift;
    my $i = $self->{+INDEX}--;

    if ($i < 0) {
        $self->{+INDEX} = 0;
        return;
    }

    my $rows = $self->_rows;
    return if $i > @$rows;
    return $rows->[$i];
}

sub copy {
    my $class = shift;
    my ($select, %params) = @_;

    croak "copy() cannot be called in void context" unless defined(wantarray);

    return $class->new(
        SOURCE()   => $select->{+SOURCE},
        LIMIT()    => $select->{+LIMIT},
        ORDER_BY() => $select->{+ORDER_BY},
        PREFETCH() => $select->{+PREFETCH},
        WHERE()    => $select->{+WHERE},

        %params,
    );
}

sub clone {
    my $self = shift;
    my %params = @_;

    croak "clone() cannot be called in void context" unless defined(wantarray);

    my $class = blessed($self);

    return $class->copy($self);
}

sub _parse_boolean_args {
    my $self = shift;

    return $self->parse_hash_arg(@_) unless @_ == 1 && blessed($_[0]) && $_[0]->isa(__PACKAGE__);
    return $_[0]->where;
}

sub _and {
    my $self = shift;
    my $where1 = $self->{+WHERE};
    my $where2 = $self->_parse_boolean_args(@_);

    return $self->clone(WHERE() => $where2) unless $where1;

    my $where = ['-and' => [$where1, $where2]];

    $self->clone(WHERE() => $where);
}

sub _or {
    my $self = shift;
    my $where1 = $self->{+WHERE};
    my $where2 = $self->_parse_boolean_args(@_);

    return $self->clone(WHERE() => $where2) unless $where1;

    my $where = ['-or' => [$where1, $where2]];

    $self->clone(WHERE() => $where);
}

# Do these last to avoid conflicts with the operators
{
    no warnings 'once';
    *and = \&_and;
    *or  = \&_or;
}

1;

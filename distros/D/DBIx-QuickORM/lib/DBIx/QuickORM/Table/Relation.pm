package DBIx::QuickORM::Table::Relation;
use strict;
use warnings;

our $VERSION = '0.000004';

use Carp qw/croak/;

use DBIx::QuickORM::Util::HashBase qw{
    <table
    +using
    +on
    <method
    <on_delete
    <prefetch
    <gets_one
    <gets_many
};

my %VALID_METHODS = (
    find   => 1,
    select => 2,
);

sub method_is_valid { $VALID_METHODS{$_[-1]} }

sub init {
    my $self = shift;

    croak "'table' is a required attribute"   unless $self->{+TABLE};
    croak "'method' is a required attribute"  unless $self->{+METHOD};

    croak "You must specify either 'using' or 'on'" unless $self->{+USING} || $self->{+ON};
    croak "You cannot combiner 'using' and 'on'" if $self->{+USING} && $self->{+ON};

    if (my $on = $self->{+ON}) {
        croak "'on' must be a hashref mapping columns in the primary table to columns in the joining table" unless ref($on) eq 'HASH';
    }

    if (my $using = $self->{+USING}) {
        $using = $self->{+USING} = [$using] unless ref($using);
        croak "'using' must be an arrayref of columns that exist in both tables" unless ref($using) eq 'ARRAY';
    }

    my $count = $self->method_is_valid($self->{+METHOD}) or croak "'$self->{+METHOD}' is not a valid method";

    if ($count > 1) {
        $self->{+GETS_MANY} = 1;
        $self->{+GETS_ONE}  = 0;
    }
    else {
        $self->{+GETS_MANY} = 0;
        $self->{+GETS_ONE}  = 1;
    }

    $self->{+PREFETCH} //= 0;
}

sub local_columns {
    my $self = shift;

    return @{$self->{+USING}} if $self->{+USING};
    return sort keys %{$self->{+ON}};
}

sub foreign_columns {
    my $self = shift;

    return @{$self->{+USING}} if $self->{+USING};
    return map { $self->{+ON}->{$_} } sort keys %{$self->{+ON}};
}

sub on {
    my $self = shift;
    return $self->{+ON} //= { map {($_ => $_)} @{$self->{+USING}} };
}

sub on_sql {
    my $self = shift;
    my ($from, $as, $sort) = @_;

    if (my $on = $self->{+ON}) {
        my @fields = keys %$on;
        @fields = sort @fields if $sort;
        return join ", " => map {"${from}.$_ = ${as}.$on->{$_}"} @fields;
    }

    if (my $using = $self->{+USING}) {
        my @fields = @$using;
        @fields = sort @fields if $sort;
        return join ", " => map {"${from}.$_ = ${as}.$_"} @fields;
    }

    die "Internal error, no 'using' or 'on' are present";
}

sub display {
    my $self = shift;
    my %params = @_;

    my $on_sql = $self->on_sql(qw/A B sort/);

    my $out = "$self->{+TABLE}->$self->{+METHOD} ON($on_sql)";
    $out .= $self->{+PREFETCH} ? " PREFETCH" : " NO FETCH";
    $out .= " ON DELETE $self->{+ON_DELETE}" if $self->{+ON_DELETE} && ($params{ON_DELETE} // 1);

    return $out;
}

sub compare {
    my $self = shift;
    my ($other, %params) = @_;

    return 0 unless $self->{+TABLE} eq $other->{+TABLE};
    return 0 unless $self->{+METHOD} eq $other->{+METHOD};
    return 0 if ($self->{+PREFETCH} xor $other->{+PREFETCH});
    return 0 unless $self->on_sql(qw/A B sort/) eq $other->on_sql(qw/A B sort/);

    if ($params{ON_DELETE} // 1) {
        return 0 if ($self->{+ON_DELETE} xor $other->{+ON_DELETE});
        if ($self->{+ON_DELETE}) {
            return 0 if $self->{+ON_DELETE} ne $other->{+ON_DELETE};
        }
    }

    return 1;
}

1;

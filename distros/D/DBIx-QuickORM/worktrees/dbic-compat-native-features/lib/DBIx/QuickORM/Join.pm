package DBIx::QuickORM::Join;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;
use Sub::Util qw/set_subname/;
use DBIx::QuickORM::Join::Row;

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Source';
with 'DBIx::QuickORM::Role::Linked';

use Object::HashBase qw{
    <schema
    <primary_source
    <join_as
    <row_class

    <order
    <lookup
    <components

    <connection
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Join - A query source built from joined tables.

=head1 DESCRIPTION

A source (see L<DBIx::QuickORM::Role::Source>) representing one or more tables
joined together. Each component table is given a short alias; the primary
source is the first component, and additional tables are added with the
C<join> / C<left_join> / C<right_join> / C<inner_join> methods, each of which
returns a clone of the join with the new component added.

The join produces aliased SQL via C<source_db_moniker> and aliased fetch
fields via C<fields_to_fetch>, and can fracture a flat fetched row back into
per-alias data with C<fracture>. Joins have no primary key and are not
directly cachable.

=head1 SYNOPSIS

    my $join = DBIx::QuickORM::Join->new(
        schema         => $schema,
        primary_source => $table,
    );

    my $joined = $join->left_join($link);

=head1 ATTRIBUTES

=over 4

=item schema

The schema the joined tables belong to.

=item primary_source

The first/anchor table of the join.

=item join_as

Internal alias generator state (the next alias to hand out).

=item row_class

Row class used for fetched rows; defaults to L<DBIx::QuickORM::Join::Row>.

=item order

Arrayref of component aliases in join order.

=item lookup

Hashref mapping a table's ORM name to the aliases it has been joined as.

=item components

Hashref mapping each alias to its component spec (table, link, from, type).

=item connection

The L<DBIx::QuickORM::Connection> the join will be queried through, when
known. Used to quote identifiers with the active driver's quoting rules;
without one, standard double quotes are used.

=back

=cut

# {{{ Role::Source interface

sub source_orm_name { 'JOIN' }

sub primary_key    { }
sub fields_to_omit { }

sub fields_list_all {
    my $self = shift;
    croak "fields_list_all() is not supported on a join source, select fields explicitly instead";
}

sub field_db_name {
    my $self = shift;
    my ($proto) = @_;
    my ($from, $t, $field) = $self->_field_source($proto, no_fatal => 1);
    return $proto unless $t;
    my $db = $t->field_db_name($field);
    return defined($from) ? "$from.$db" : $db;
}

sub field_orm_name {
    my $self = shift;
    my ($proto) = @_;
    my ($from, $t, $field) = $self->_field_source($proto, no_fatal => 1);
    return $proto unless $t;
    my $orm = $t->field_orm_name($field);
    return defined($from) ? "$from.$orm" : $orm;
}

sub field_is_generated {
    my $self = shift;
    my ($proto) = @_;
    my (undef, $t, $field) = $self->_field_source($proto, no_fatal => 1);
    return 0 unless $t;
    return $t->field_is_generated($field);
}

sub source_has_aliases {
    my $self = shift;
    for my $as (@{$self->{+ORDER}}) {
        return 1 if $self->{+COMPONENTS}->{$as}->{table}->source_has_aliases;
    }
    return 0;
}

# }}} Role::Source interface

sub init {
    my $self = shift;
    croak "'schema' is required"         unless $self->{+SCHEMA};
    croak "'primary_source' is required" unless $self->{+PRIMARY_SOURCE};

    $self->{+JOIN_AS} = 'a';

    $self->{+ORDER}      //= [];
    $self->{+LOOKUP}     //= {};
    $self->{+COMPONENTS} //= {};

    my $first = $self->{+JOIN_AS}++;
    push @{$self->{+ORDER}}                                                => $first;
    push @{$self->{+LOOKUP}->{$self->{+PRIMARY_SOURCE}->source_orm_name}} => $first;
    $self->{+COMPONENTS}->{$first} = {table => $self->{+PRIMARY_SOURCE}, as => $first};

    $self->{+ROW_CLASS} //= 'DBIx::QuickORM::Join::Row';
}

=pod

=head1 PUBLIC METHODS

=over 4

=item $parts = $join->fracture(\%row)

Split a flat fetched row (with C<alias.field> keys) into an arrayref of
per-component pieces, one per alias that has any non-null value. Each piece
carries the component source, its data, alias, and link.

=cut

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

=pod

=item $copy = $join->clone(%overrides)

Return a shallow copy of the join with the order, lookup, and components
containers duplicated so the copy can be extended independently.

=cut

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

=pod

=item $ref = $join->source_db_moniker

Return a scalar reference to the SQL C<FROM> fragment for the join, including
each aliased table and its C<ON> conditions.

=cut

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

        # Quote the alias and ON-clause column references so a caller-supplied
        # alias (or a reserved-word/mixed-case column) cannot break out into
        # raw SQL. Each side of an "alias.column" pair is quoted separately so
        # it becomes "alias"."column", not the wrong "alias.column".
        my $qas = $self->_quote_identifier($as);

        if ($type =~ m/^CROSS$/i) {
            # CROSS JOIN takes no ON clause (PostgreSQL rejects one).
            $out .= " CROSS JOIN " . $table->source_db_moniker . " AS $qas";
        }
        elsif ($link) {
            my $lc = $link->local_columns;
            my $oc = $link->other_columns;

            my $qfrom = $self->_quote_identifier($from);
            my @cols;
            for (my $i = 0; $i < @$lc; $i++) {
                push @cols => $qas . '.' . $self->_quote_identifier($oc->[$i])
                            . ' = '
                            . $qfrom . '.' . $self->_quote_identifier($lc->[$i]);
            }

            $out .= $type =~ m/join/i ? " $type " : " $type JOIN ";
            $out .= $table->source_db_moniker . " AS $qas ON (" . join(' AND ' => @cols) . ")";
        }
        else {
            $out = $table->source_db_moniker . " AS $qas";
        }
    }

    return \$out;
}

=pod

=item ($from, $table, $field) = $join->_field_source($proto, %params)

Resolve a C<alias.field> (or bare C<field>) proto into its alias, table, and
field name. Croaks if the field cannot be resolved unless C<no_fatal> is set.

=cut

sub _field_source {
    my $self = shift;
    my ($proto, %params) = @_;
    my ($field, $from) = reverse split /\./, $proto;

    if (defined $from) {
        my $c = $self->{+COMPONENTS}->{$from};
        unless ($c) {
            return undef if $params{no_fatal};
            croak "'$from' is not an alias in this join";
        }
        return ($from, $c->{table}, $field);
    }

    for my $alias (@{$self->{+ORDER}}) {
        my $c = $self->{+COMPONENTS}->{$alias};
        my $t = $c->{table};
        next unless $t->has_field($field);
        return ($alias, $t, $field);
    }

    return undef if $params{no_fatal};
    croak "This join does not have a '$field' field";
}

=pod

=item $type = $join->field_type($proto)

=item $affinity = $join->field_affinity($proto, $dialect)

=item $bool = $join->has_field($proto)

Delegate field type, affinity, and existence checks to the component table
that owns the given C<alias.field> (or bare C<field>) proto.

=cut

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
    return 0 unless $t;
    return $t->has_field($field);
}

=pod

=item $fields = $join->fields_to_fetch

Return an arrayref of aliased select expressions (literal-SQL scalar refs)
covering every component table's fetch fields, each aliased as
C<"alias.field">.

=cut

sub fields_to_fetch {
    my $self = shift;

    my @fields;

    for my $as (@{$self->{+ORDER}}) {
        my $c = $self->{+COMPONENTS}->{$as};
        my $t = $c->{table};
        # Quote the "alias"."column" reference (each part separately) so it
        # matches the quoted alias the FROM clause defines; the AS label keeps
        # its "alias.field" form since that is the result-set column key.
        push @fields => map {
            my $db  = $t->field_db_name($_);
            my $ref = $self->_quote_identifier($as) . '.' . $self->_quote_identifier($db);
            \("$ref AS " . $self->_quote_identifier("$as.$db"));
        } @{$t->fields_to_fetch};
    }

    return \@fields;
}

=pod

=item $quoted = $join->_quote_identifier($name)

Quote an identifier using the connection's driver rules when a connection is
available, falling back to standard double quotes.

=cut

sub _quote_identifier {
    my $self = shift;
    my ($name) = @_;

    my $con = $self->{+CONNECTION} or return qq{"$name"};
    return $con->dbh->quote_identifier($name);
}

=pod

=item $links = $join->links

Return an arrayref of all links from every component table in the join.

=cut

sub links {
    my $self = shift;

    my @out;

    for my $as (@{$self->{+ORDER}}) {
        my $table = $self->{+COMPONENTS}->{$as}->{table};
        push @out => @{$table->links};
    }

    return \@out;
}

=pod

=item $table = $join->from($alias_or_name)

Resolve an alias or table name to its component table. Croaks when a table
name is ambiguous (joined more than once) or cannot be resolved.

=cut

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

=pod

=item %params = $join->_join_params(@args)

Normalize join arguments: a single argument is treated as the C<link>,
otherwise the arguments are taken as a key/value list.

=cut

sub _join_params {
    my $self = shift;

    return (link => $_[0]) if @_ == 1;
    return @_;
}

=pod

=item $copy = $join->_join(%params)

Clone the join and add a new component for the given link, resolving its
alias and source-of-join (C<from>) and appending it to the order, lookup, and
components. Returns the new join. A C<CROSS> type component may omit the link
and pass C<< table => $name >> instead; it joins without an C<ON> clause.

=cut

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

    my $is_cross = ($type // '') =~ m/^CROSS$/i;
    croak "A 'link' is required (only CROSS joins may omit it)" unless $link || $is_cross;

    my $joined;
    if ($link) {
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

        $joined = $self->schema->table($link->other_table);
    }
    else {
        # Link-less CROSS join: no ON clause is emitted, so no 'from' side is
        # needed either, only the table being joined.
        my $table = $params{table} or croak "A 'table' is required for a link-less CROSS join";
        $joined = blessed($table) ? $table : $self->schema->table($table);
        $from = undef;
    }

    push @{$self->{+ORDER}} => $as;

    push @{$self->{+LOOKUP}->{$joined->source_orm_name}} => $as;

    $self->{+COMPONENTS}->{$as} = {
        as    => $as,
        table => $joined,
        link  => $link,
        from  => $from,
        type  => $type,
    };

    return $self;
}

=pod

=item $copy = $join->join($link, ...)

=item $copy = $join->left_join($link, ...)

=item $copy = $join->right_join($link, ...)

=item $copy = $join->inner_join($link, ...)

Return a clone of the join with another table added via the given link. The
named variants set the join type (plain, C<LEFT>, C<RIGHT>, C<INNER>). A
single argument is taken as the link; otherwise pass C<link>, C<as>,
C<from>, etc. as key/value pairs.

=cut

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

=pod

=back

=cut

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut

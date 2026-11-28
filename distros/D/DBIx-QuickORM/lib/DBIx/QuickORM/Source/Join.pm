package DBIx::QuickORM::Source::Join;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak confess/;
use Scalar::Util qw/refaddr/;

use DBIx::QuickORM::JoinRow();

use Object::HashBase qw{
    <db_map
    +components
    +labels
    +label_of
    +records
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Source';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Source::Join - Tables joined together, as a source.

=head1 DESCRIPTION

A base table and the tables joined to it, as L<DBIx::QuickORM::Role::Source>
describes. Handles build joins with C<join>, C<inner_join>, and C<left_join>
(see L<DBIx::QuickORM::Handle>). Each result row is a
L<DBIx::QuickORM::JoinRow>.

Each joined table is a component with a name (its alias in the SQL), joined
from an earlier component along a foreign key link, as an inner or a left
join. A join is an immutable value: adding a component returns a new one.

Fields are named C<component.field> everywhere, so components may share
field names. The select list holds each component's default fields and
primary key.

Every component with a primary key is ingested into the lookup table (as
for a table's rows, not under C<no_cache>), and within one query the same canon row data gives the same row object. The rows
belong to no single table, so a join cannot be written through.

=head1 SYNOPSIS

    my $h = $orm->handle('orders')
        ->join('customers')
        ->left_join(
            'employees',
            as   => 'rep',
            link => {rep_id => 'id'},
        );

    my $source = $h->source;    # a DBIx::QuickORM::Source::Join

=head1 ATTRIBUTES

=over 4

=item $map = $join->db_map

Required: the L<DBIx::QuickORM::Map>.

=item components => [{as => $name, table => $table}, {as => $name, table => $table, type => 'inner' or 'left', from => $name, link => \%link}, ...]

Required at construction: the base table, then each joined component in
order. C<link> is C<< {from_field => field} >>, from the component named
C<from> to this one.

Croaks without at least the base table, for a table not in the map, a
component name already taken, or a C<from> that names no earlier component.

=back

=cut

sub init {
    my $self = shift;

    my $map        = $self->{+DB_MAP} or croak "A 'db_map' is required";
    my $components = $self->{+COMPONENTS};
    croak "'components' must be an arrayref of at least the base table" unless ref($components) eq 'ARRAY' && @$components;

    my (%seen, %labels, %label_of, %records);
    for my $i (0 .. $#$components) {
        my ($as, $table, $from) = @{$components->[$i]}{qw/as table from/};
        my $t = $map->table($table) or confess "The table '$table' is not in the database map";
        confess "The join has no component named '$from'"      if $i && !$seen{$from};
        confess "The join already has a component named '$as'" if $seen{$as}++;

        my @fields = sort keys %{$t->{fields}};
        for my $k (0 .. $#fields) {
            my $label = "qorm_${i}_$k";
            $labels{$label}              = [$i, $fields[$k]];
            $label_of{"$as.$fields[$k]"} = $label;
            $records{$label}             = $records{"$as.$fields[$k]"} = $t->{fields}->{$fields[$k]};
        }
    }

    $self->{+LABELS}   = \%labels;
    $self->{+LABEL_OF} = \%label_of;
    $self->{+RECORDS}  = \%records;
}

=head1 PUBLIC METHODS

=over 4

=item undef = $join->table

=item undef = $join->pk

Undef: the rows belong to no single table, so a join has no table and no
primary key.

=item () = $join->query_sql

An empty list: a join is not a query.

=item \%fields = $join->field_records

The field records by internal label and by C<component.field>.

=back

=cut

sub table     { undef }
sub pk        { undef }
sub query_sql { () }

sub field_records { $_[0]->{+RECORDS} }

=pod

=over 4

=item $join2 = $join->extend($type, $table, as => $name, from => $name, link => \%link)

A new join with one more component. C<$type> is C<inner> or C<left>. C<as>
defaults to the table name and C<from> to the base table's component.

Croaks for any other C<$type>, and as construction does for a bad table,
C<as>, or C<from>.

=back

=cut

sub extend {
    my $self = shift;
    my ($type, $table, %opts) = @_;

    croak "A join is 'inner' or 'left'" unless $type eq 'inner' || $type eq 'left';
    my $component = {type => $type, table => $table, as => $opts{as} // $table, from => $opts{from} // $self->{+COMPONENTS}->[0]->{as}, link => $opts{link}};
    return ref($self)->new(db_map => $self->{+DB_MAP}, components => [@{$self->{+COMPONENTS}}, $component]);
}

=pod

=over 4

=item $table = $join->component_table($name)

The table of a component, the base table's for an undef name. Croaks when
there is no such component.

=back

=cut

sub component_table {
    my $self       = shift;
    my ($as)       = @_;
    my $components = $self->{+COMPONENTS};
    return $components->[0]->{table} unless defined $as;
    my ($c) = grep { $_->{as} eq $as } @$components;
    confess "The join has no component named '$as'" unless $c;
    return $c->{table};
}

=pod

=over 4

=item $fields = $join->select_fields($given)

The labeled select list, a hashref of label to C<component.field>.

With no C<$given>, each component's default fields. For an arrayref of
C<component.field> names, those. Either way each component's primary key is
added. Computed fields (a hashref) come back as they are.

Croaks for a plain field name (in either shape) that is not
C<component.field>, or that names no component or field.

=back

=cut

sub select_fields {
    my $self = shift;
    my ($given) = @_;

    my $label_of = $self->{+LABEL_OF};
    my @bad      = grep { !ref($_) && !$label_of->{$_} } ref($given) eq 'HASH' ? values %$given : @{$given // []};
    confess "A join names fields as component.field; '$bad[0]' is not a field of a component" if @bad;
    return $given                                                                             if ref($given) eq 'HASH';

    my $map = $self->{+DB_MAP};
    my @names;
    for my $c (@{$self->{+COMPONENTS}}) {
        my $t = $map->table($c->{table});
        push @names => map { "$c->{as}.$_" } @{$given ? [] : $t->{default_fields} // [sort keys %{$t->{fields}}]}, @{$t->{pk} // []};
    }

    return {map { $label_of->{$_} => $_ } @{$given // []}, @names};
}

=pod

=over 4

=item ($sql, \@binds) = $join->from_sql($dialect)

The base table and every C<JOIN ... ON ...>, each table with its component
name as its alias. No binds.

=back

=cut

sub from_sql {
    my $self = shift;
    my ($dialect) = @_;

    my $q = sub {
        join '.' => map { $dialect->quote_identifier($_) } @_;
    };
    my ($base, @joined) = @{$self->{+COMPONENTS}};

    my $sql = $q->($base->{table}) . ' AS ' . $q->($base->{as});
    for my $c (@joined) {
        my $on = join ' AND ' => map { $q->($c->{from}, $_) . ' = ' . $q->($c->{as}, $c->{link}->{$_}) } sort keys %{$c->{link}};
        $sql .= ' ' . uc($c->{type}) . ' JOIN ' . $q->($c->{table}) . ' AS ' . $q->($c->{as}) . " ON $on";
    }

    return ($sql, []);
}

=pod

=over 4

=item (\@rows, \&build) = $join->results($orm, \@raw, $ingest, @class)

Splits each fetched row into its components' row data and builds each into a
L<DBIx::QuickORM::JoinRow>.

With C<$ingest>, the row data of components with a primary key is ingested. A
left-joined component that matched nothing (its primary key, or every field
without one, NULL) is undef.

Component rows use their tables' row classes, the same canon row data giving
the same row object for the whole result. With C<@class> undef, each row is
the join row's raw C<data> instead. Croaks for any other C<@class>.

=back

=cut

sub results {
    my $self = shift;
    my ($orm, $raw, $ingest, @class) = @_;
    confess "A join handle's row_class can only be undef (for each row's raw data); its components use their tables' row classes" if @class && defined $class[0];

    my $components = $self->{+COMPONENTS};
    my $labels     = $self->{+LABELS};
    my $map        = $self->{+DB_MAP};
    my $lookup     = $orm->connection->lookup;

    my @rows;
    for my $row (@$raw) {
        my (%data, @parts);
        for my $label (keys %$row) {
            my ($i, $field) = @{$labels->{$label}};
            $data{"$components->[$i]->{as}.$field"} = $parts[$i]->{$field} = $row->{$label};
        }

        for my $i (0 .. $#$components) {
            my $c    = $components->[$i];
            my $part = $parts[$i] // {};
            my $pk   = $map->pk($c->{table});
            my @key  = $pk && @$pk ? @$pk : keys %$part;
            if (($c->{type} // '') eq 'left' && !grep { defined $part->{$_} } @key) {
                $parts[$i] = undef;
                next;
            }
            $parts[$i] = $ingest && $pk && @$pk ? $lookup->ingest($c->{table}, $part) : $part;
        }

        push @rows => [\%data, \@parts];
    }

    return (\@rows, sub { $_[0]->[0] }) if @class;

    my @aliases  = map { $_->{as} } @$components;
    my @builders = map { $orm->_row_builder($_->{table}) } @$components;
    my %built;
    my $build = sub {
        my ($data, $parts) = @{$_[0]};
        my %rows;
        for my $i (0 .. $#$components) {
            my $part = $parts->[$i] or next;
            my $make = $builders[$i];
            $rows{$aliases[$i]} = $built{refaddr($part)} //= $make ? $make->($part) : $part;
        }
        return DBIx::QuickORM::JoinRow->new(aliases => \@aliases, rows => \%rows, data => $data);
    };

    return (\@rows, $build);
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
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

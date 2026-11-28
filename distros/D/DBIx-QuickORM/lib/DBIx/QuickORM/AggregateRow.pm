package DBIx::QuickORM::AggregateRow;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;

use Object::HashBase qw{
    <orm
    <source
    <columns
    <row_data
};

use Role::Tiny::With qw/with/;
with 'DBIx::QuickORM::Role::Row';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::AggregateRow - A computed row that knows its columns' types and foreign keys.

=head1 DESCRIPTION

The row a grouped or computed handle hands out when the ORM uses row
objects (see L<DBIx::QuickORM::Handle/Computed columns>). Each column carries
what its spec gave it: a type to inflate through, and foreign keys to follow.

It has no primary key, so it is never canonical: C<update>, C<delete>,
C<refresh>, and C<is_canon> croak. Field reads work as in
L<DBIx::QuickORM::Role::Row>, without any fetch: the row holds every column
it will ever have.

=head1 SYNOPSIS

    use DBIx::QuickORM::Value qw/sql/;

    my $stat = $orm->handle('posts')
        ->group_by('user_id')
        ->fields({
            user_id => 'user_id',
            posts   => [count => '*'],
            top     => [max => 'views'],
        })
        ->first;

    my $count  = $stat->field('posts');
    my $author = $stat->follow_fk('users')->only;    # user_id keeps its foreign key

    my $signups = $orm->handle('users')
        ->fields({
            total  => sql('COUNT(*)'),
            newest => [max => 'created'],
        })
        ->only;

    my $year = $signups->field('newest')->datetime_ref->year;    # MAX keeps the field's type: a DateTime

=head1 ATTRIBUTES

=over 4

=item $orm = $row->orm

=item $source = $row->source

The L<DBIx::QuickORM> and the handle's source.

=item \%columns = $row->columns

Each column name mapped to its field record: C<orm_type>, C<db_type>,
C<type>, C<size>, C<affinity>, and C<fk> (C<< {$table => [{$column =>
$field}]} >>), each when known.

=item \%data = $row->row_data

The fetched values, keyed by column name.

=back

=cut

sub init {
    my $self = shift;
    croak "An 'orm' is required"         unless $self->{+ORM};
    croak "'columns' must be a hashref"  unless ref($self->{+COLUMNS}) eq 'HASH';
    croak "'row_data' must be a hashref" unless ref($self->{+ROW_DATA}) eq 'HASH';
}

=head1 PUBLIC METHODS

=over 4

=item $table = $row->table

Undef: the row belongs to no table.

=item $row->set_row_data(\%data)

Croaks: an aggregate row's data is never replaced, so C<update_row> and
C<refresh_row> refuse one before anything is sent.

=back

=cut

sub table        { undef }
sub set_row_data { croak "An aggregate row's data cannot be replaced" }

=pod

=over 4

=item $value = $row->inflated_field($name)

=item @values = $row->inflated_fields(\@names)

=item @values = $row->inflated_fields(@names)

Values inflated through each column's type, as L<DBIx::QuickORM::Role::Row>
hands them out. C<field> and C<fields> come from there. Croaks for a name
that is not a column.

=back

=cut

sub inflated_field { ($_[0]->inflated_fields($_[1]))[0] }

sub inflated_fields {
    my $self  = shift;
    my @names = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
    return map { $self->_inflated_value($_, $self->_column($_)) } @names;
}

=pod

=over 4

=item @raw = $row->raw_fields(\@names)

=item @raw = $row->raw_fields(@names)

Values as fetched. C<raw_field> comes from L<DBIx::QuickORM::Role::Row>.
Croaks for a name that is not a column.

=back

=cut

sub raw_fields {
    my $self  = shift;
    my @names = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
    $self->_column($_) for @names;
    return @{$self->{+ROW_DATA}}{@names};
}

=pod

=over 4

=item $h = $row->follow_fk($other_table)

=item $h = $row->follow_fk($other_table, link => {$column => $target_field})

=item $h = $row->follow_fk($other_table, via => {$column => $target_field})

A handle on the rows of C<$other_table> that a column's foreign key reaches.
Without C<link>, exactly one foreign key of the columns must point at
C<$other_table>. C<link> names one column and the field its key targets.
C<via> does the same for a column with no key. The column and the target
field must exist.

The handle is C<single> when the target is the other table's primary key or
a unique key, and C<multi> otherwise. A NULL value matches no rows.

Croaks when no foreign key (or more than one, without C<link>) points at
C<$other_table>, when C<link> matches none, and when given both C<link> and
C<via>.

=back

=cut

sub follow_fk {
    my $self = shift;
    my ($other, %params) = @_;

    my @unknown = sort grep { $_ ne 'link' && $_ ne 'via' } keys %params;
    croak "Unknown argument(s) to follow_fk(): " . join(', ' => @unknown) if @unknown;
    croak "follow_fk() needs the table to follow to" unless defined($other) && length($other);
    croak "Give 'link' or 'via', not both" if defined($params{link}) && defined($params{via});

    my $columns = $self->{+COLUMNS};
    if (defined(my $via = $params{via})) {
        croak "'via' must be one {column => target_field}" unless ref($via) eq 'HASH' && keys(%$via) == 1;
        my ($column, $field) = %$via;
        croak "'via' names '$column', which is not a column of the aggregate row"           unless $columns->{$column};
        croak "The table '$other' is not in the database map"                               unless $self->{+ORM}->db_map->table($other);
        croak "'via' names '" . ($field // 'undef') . "', which is not a field of '$other'" unless defined($field) && $self->{+ORM}->db_map->field($other, $field);
        return $self->{+ORM}->_fk_handle($other, {$field => $self->{+ROW_DATA}->{$column}});
    }

    my @links = map {
        my $column = $_;
        map { [$column, values %$_] } @{(($columns->{$column}->{fk} // {})->{$other}) // []};
    } sort keys %$columns;

    my $link = $params{link};
    if (defined $link) {
        croak "'link' must be one {column => target_field}" unless ref($link) eq 'HASH' && keys(%$link) == 1;
        my ($column, $field) = %$link;
        @links = grep { $_->[0] eq $column && $_->[1] eq $field } @links;
        croak "The link ($column => $field) matches no foreign key from a column to '$other'" unless @links;
    }

    croak "No column of the aggregate row has a foreign key to '$other'" unless @links;
    croak "More than one column of the aggregate row has a foreign key to '$other'; choose one with 'link'" if @links > 1;

    my ($column, $field) = @{$links[0]};
    return $self->{+ORM}->_fk_handle($other, {$field => $self->{+ROW_DATA}->{$column}});
}

=head1 PRIVATE METHODS

=over 4

=item \%column = $row->_column($name)

The column's field record. Croaks when there is no such column.

=back

=cut

sub _column {
    my $self = shift;
    my ($name) = @_;
    return $self->{+COLUMNS}->{$name} // croak "The aggregate row has no column '" . ($name // 'undef') . "'";
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

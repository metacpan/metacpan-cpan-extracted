package DBIx::QuickORM::Handle::Column;
use strict;
use warnings;

our $VERSION = '0.000028';

use Carp qw/croak/;

use Object::HashBase qw{
    <handle
    <column
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Handle::Column - Aggregate and single-column reads for a handle.

=head1 DESCRIPTION

A thin wrapper binding a L<DBIx::QuickORM::Handle> to one column (or column
expression) so you can read aggregates over it (C<sum>/C<min>/C<max>/C<avg>/
C<count>/C<func>) or pull the column's values directly (C<all>/C<iterator>).

Obtain one from a handle:

    my $col = $con->handle('orders')->where({paid => 1})->column('total');

Every fetch runs a single C<SELECT> that reuses the handle's C<where> (and any
C<group_by>/C<having>), returns the raw database scalar (no type inflation, like
C<count()>), and never enters the identity map.

=head1 SYNOPSIS

    my $orders = $con->handle('orders');

    my $total   = $orders->column('total')->sum;
    my $biggest = $orders->column('total')->max;
    my $joined  = $orders->column('sku')->func('GROUP_CONCAT');

    # Literal expression (emitted verbatim):
    my $revenue = $orders->column(\'price * qty')->sum;

    # Per-group values line up with a grouped handle:
    my @totals = $orders->group_by('category')->column('total')->all;

=head1 ATTRIBUTES

=over 4

=item handle

The L<DBIx::QuickORM::Handle> this column reads through.

=item column

The column: a plain string name, or a scalar reference holding literal SQL.

=back

=cut

sub init {
    my $self = shift;

    croak "'handle' is a required attribute"
        unless $self->{+HANDLE} && $self->{+HANDLE}->isa('DBIx::QuickORM::Handle');

    croak "'column' is a required attribute" unless defined $self->{+COLUMN};
}

=pod

=head1 PUBLIC METHODS

=over 4

=item $val = $col->sum

=item $val = $col->min

=item $val = $col->max

=item $val = $col->avg

=item $val = $col->count

Run the matching SQL aggregate over the column and return the scalar result
(C<undef> when there are no rows).

=cut

sub sum   { $_[0]->_aggregate('SUM') }
sub min   { $_[0]->_aggregate('MIN') }
sub max   { $_[0]->_aggregate('MAX') }
sub avg   { $_[0]->_aggregate('AVG') }
sub count { $_[0]->_aggregate('COUNT') }

=pod

=item $val = $col->func($name)

Run an arbitrary single-argument aggregate C<$name> over the column (e.g.
C<< $col->func('GROUP_CONCAT') >>). The function name must be a bare identifier
(word characters only).

=cut

sub func {
    my $self = shift;
    my ($name) = @_;

    croak "func() requires an aggregate function name" unless defined $name && length $name;
    croak "Aggregate function name '$name' is not a bare identifier" unless $name =~ m/\A\w+\z/;

    return $self->{+HANDLE}->_aggregate_one("${name}(" . $self->_column_sql . ")");
}

=pod

=item @vals = $col->all

The column's value from every row, as a list of plain scalars.

=item $iter = $col->iterator

An iterator yielding the column's value one row at a time.

=back

=cut

sub all      { $_[0]->{+HANDLE}->_aggregate_all($_[0]->_column_sql) }
sub iterator { $_[0]->{+HANDLE}->_aggregate_iterator($_[0]->_column_sql) }

=pod

=head1 PRIVATE METHODS

=over 4

=item $val = $col->_aggregate($func)

Apply an aggregate function to the column expression and fetch the scalar.

=item $sql = $col->_column_sql

The column rendered as SQL: a quoted identifier for a plain name, or the literal
SQL verbatim for a scalar reference.

=back

=cut

sub _aggregate {
    my $self = shift;
    my ($func) = @_;
    return $self->{+HANDLE}->_aggregate_one("${func}(" . $self->_column_sql . ")");
}

sub _column_sql {
    my $self = shift;

    my $col = $self->{+COLUMN};
    return $$col if ref($col) eq 'SCALAR';

    my $handle = $self->{+HANDLE};
    my $db     = $handle->source->field_db_name($col);
    return $handle->connection->dbh->quote_identifier($db);
}

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

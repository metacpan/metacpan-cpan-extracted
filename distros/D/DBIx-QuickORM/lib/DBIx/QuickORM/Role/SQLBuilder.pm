package DBIx::QuickORM::Role::SQLBuilder;
use strict;
use warnings;

our $VERSION = '0.000026';

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::SQLBuilder - Role for SQL statement builders.

=head1 DESCRIPTION

Interface implemented by SQL builders that turn ORM sources, field lists, and
where-clauses into statement/bind pairs. Consumers provide the per-statement
builders; this role supplies a helper for building a row's primary-key
where-clause.

A source's columns may use one name in the ORM and a different name in the
database. Implementations B<must> emit database names in all generated SQL
(translating field lists, where-clauses, order-by, insert/update data, and
returning lists from ORM names to database names via the source), and callers
restore ORM names on fetched rows with C<qorm_row_to_orm>. Literal SQL passed
by the caller is never rewritten.

=head1 SYNOPSIS

    package My::SQLBuilder;
    use Role::Tiny::With;
    with 'DBIx::QuickORM::Role::SQLBuilder';

    sub qorm_select { ... }
    # ...and the other required methods

=head1 REQUIRED METHODS

Consumers must provide C<qorm_select>, C<qorm_insert>, C<qorm_update>,
C<qorm_delete>, C<qorm_where>, C<qorm_and>, and C<qorm_or>.

=cut

requires qw{
    qorm_select
    qorm_insert
    qorm_update
    qorm_delete
    qorm_where

    qorm_and
    qorm_or
};

=pod

=head1 PUBLIC METHODS

=over 4

=item $where = $builder->qorm_where_for_row($row)

Return a where-clause (the row's primary-key hashref) that uniquely
identifies the given row.

=item $orm_row = $builder->qorm_row_to_orm($source, \%row)

Return a new hashref with a fetched row's keys remapped from database column
names back to ORM names for the given source. Unknown keys pass through
unchanged.

=back

=cut

sub qorm_where_for_row {
    my $self = shift;
    my ($row) = @_;
    return $row->primary_key_hashref;
}

sub qorm_row_to_orm {
    my $self = shift;
    my ($source, $row) = @_;

    return $row unless $source && $source->can('field_orm_name');
    return $row if $source->can('source_has_aliases') && !$source->source_has_aliases;

    return { map { $source->field_orm_name($_) => $row->{$_} } keys %$row };
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

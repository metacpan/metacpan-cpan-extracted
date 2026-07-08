package DBIx::QuickORM::Role::Source;
use strict;
use warnings;

our $VERSION = '0.000028';

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Source - Role for things that can be queried.

=head1 DESCRIPTION

A "source" is anything a query can run against: a table, a view, a join, or
a literal SQL fragment. This role defines the interface the query and SQL
layers rely on. Consumers include L<DBIx::QuickORM::Schema::Table>,
L<DBIx::QuickORM::Join>, and L<DBIx::QuickORM::LiteralSource>.

=head1 REQUIRED METHODS

=over 4

=item $sql = $source->source_db_moniker

The SQL naming the source: a table name, C<"table AS alias">, or literal SQL.

=item $name = $source->source_orm_name

The abstract source kind: C<TABLE>, C<VIEW>, C<JOIN>, or C<LITERAL>.

=item $class = $source->row_class

=item $cols = $source->primary_key

=item $type = $source->field_type($field)

=item $aff = $source->field_affinity($field, $dialect)

=item $bool = $source->has_field($field)

=item $db_name = $source->field_db_name($field)

The database name for a field, given either its ORM or database name. Idempotent
and used by the SQL builder to emit database names; an unknown field is returned
unchanged.

=item $orm_name = $source->field_orm_name($field)

The ORM name for a field, given either its ORM or database name. Idempotent and
used to remap fetched result keys back to ORM names; an unknown field is
returned unchanged.

=item $bool = $source->field_is_generated($field)

True if the named field is a database-generated column (stored or virtual
C<GENERATED>). Used by the row and SQL layers to keep generated columns out of
C<INSERT> / C<UPDATE> column lists. Unknown fields return false.

=item $bool = $source->source_has_aliases

True when the source has any column whose ORM name differs from its database
name. Lets the SQL and row layers skip name translation entirely when there is
nothing to translate.

=item $fields = $source->fields_to_fetch

=item $fields = $source->fields_to_omit

=item $fields = $source->fields_list_all

=back

=head1 PROVIDED METHODS

=over 4

=item $bool = $source->cachable

True when the source has a primary key (so its rows can be identity-mapped and
cached), false otherwise.

=item $bool = $source->is_writable

True for a real source that C<INSERT> / C<UPDATE> / C<DELETE> can target. A
derived-table (subquery) source overrides this to false so writes croak with a
clear message instead of failing deep in statement construction.

=back

=cut

sub cachable {
    my $pk = $_[0]->primary_key or return 0;
    return 1 if @$pk;
    return 0;
}

sub is_writable { 1 }

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

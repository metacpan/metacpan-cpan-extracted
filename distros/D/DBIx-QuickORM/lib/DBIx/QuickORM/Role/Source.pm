package DBIx::QuickORM::Role::Source;
use strict;
use warnings;

our $VERSION = '0.000020';

use Carp qw/croak confess/;

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

=item $fields = $source->fields_to_fetch

=item $fields = $source->fields_to_omit

=item $fields = $source->fields_list_all

=back

=cut

sub cachable {
    my $pk = $_[0]->primary_key or return 0;
    return 1 if @$pk;
    return 0;
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut

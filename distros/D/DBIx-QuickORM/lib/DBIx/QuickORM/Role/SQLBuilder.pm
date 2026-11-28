package DBIx::QuickORM::Role::SQLBuilder;
use strict;
use warnings;

our $VERSION = '0.000031';

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::SQLBuilder - The interface a handle builds SQL through.

=head1 DESCRIPTION

A L<DBIx::QuickORM::Handle> turns its request into SQL through the ORM's
C<sql_builder>. L<DBIx::QuickORM::SQLBuilder::SQLAbstract> is the default.
Any class composing this role can replace it. The ORM's CRUD operations write
their own SQL and do not use the builder.

Each method but C<combine_where> returns new SQL and a new arrayref of
binds, and executes nothing. C<combine_where> returns a condition. A bind is
C<[$field, $value]>: C<$field> names the field of the source's table the
value is compared with or written to, and decides how the value is bound. It
is undef when there is none.

A value may be a C<raw>, C<inflated>, or C<binary> marker
(L<DBIx::QuickORM::Value>), which the Connection resolves when it runs the
SQL. Identifiers are quoted through the dialect.

A C<where> and an order are opaque to everything but the builder, which
documents the syntax it accepts. Every builder must accept a hashref of field
names to plain values, meaning each field equals its value (undef: C<IS
NULL>), since the ORM builds that form itself. It must also accept value
markers as values in a C<where>.

A handle sends its C<where> with C<where_builders>: the where builders
(L<DBIx::QuickORM::Role::WhereBuilder>) to render it through, the first that
can build it winning. A builder should use them for the C<WHERE>. One that
ignores them renders every C<where> itself.

=head1 SYNOPSIS

    package My::Builder;
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::SQLBuilder';

    sub new { bless {}, shift }    # the ORM constructs a class it is given

    sub select { my ($self, $source, $dialect, %request) = @_; ... return ($sql, \@binds) }
    sub count  { ... }
    sub update { ... }
    sub delete { ... }
    sub combine_where { my ($self, %params) = @_; ... return $where }

=head1 REQUIRED METHODS

C<$source> is a L<DBIx::QuickORM::Role::Source> and C<$dialect> a
L<DBIx::QuickORM::Dialect> object. Without a C<where>, C<update> and C<delete>
write every row.

=over 4

=item ($sql, \@binds) = $builder->select($source, $dialect, fields => $fields, where => $where, where_builders => \@builders, group_by => \@fields, having => $having, order_by => $order, limit => $n, offset => $n)

A C<SELECT>. Each request key is optional. A field name anywhere may be
qualified as C<name.field>.

=over 4

=item *

C<fields>: an arrayref of field names, or a hashref of output names to what
each selects: a field name, an C<sql> marker, or C<[$FUNC, $field]> for
C<FUNC(field)> with the field quoted (the handle has checked C<$FUNC> is a
word). Without it every column is selected.

=item *

C<group_by>: field names.

=item *

C<having>: a condition in the C<where> syntax.

=item *

C<order_by>: may name output names.

=back

=item ($sql, \@binds) = $builder->count($source, $dialect, where => $where, where_builders => \@builders)

C<SELECT COUNT(*)>, its one column named C<count>.

=item ($sql, \@binds) = $builder->update($source, $dialect, \%values, where => $where, where_builders => \@builders)

An C<UPDATE> setting each field to its value. An C<sql> marker as a value is
written into the SQL with its binds.

=item ($sql, \@binds) = $builder->delete($source, $dialect, where => $where, where_builders => \@builders)

A C<DELETE> of the rows matching the C<where>.

=item $where = $builder->combine_where(op => $op, left => $left, right => $right)

One condition, in the builder's syntax, that holds when both sides hold
(C<op> C<'and'>) or when either does (C<'or'>).

This serves a handle's C<and> and C<or>: C<$left> is the handle's C<where>,
C<$right> the new condition. Value markers in either side must still work in
the result.

=back

=cut

requires qw/select count update delete combine_where/;

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

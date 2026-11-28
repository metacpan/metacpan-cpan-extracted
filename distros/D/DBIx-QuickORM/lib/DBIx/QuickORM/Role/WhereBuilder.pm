package DBIx::QuickORM::Role::WhereBuilder;
use strict;
use warnings;

our $VERSION = '0.000031';

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::WhereBuilder - The interface a handle's WHERE is rendered through.

=head1 DESCRIPTION

The SQL builder renders a handle's C<where> through a chain of where
builders: the first whose C<can_build_where> is true builds it. The chain is
the ORM's C<where_builders>, or the handle's when set. The default chain is
L<DBIx::QuickORM::WhereBuilder::RawSQL>,
L<DBIx::QuickORM::WhereBuilder::Simple>, then
L<DBIx::QuickORM::WhereBuilder::SQLAbstract>, which takes everything.

Only the C<WHERE> goes through the chain. C<having> and C<order_by> do not.

A where builder is a class or an object, and its methods are called on it as
given.

=head1 SYNOPSIS

    package My::WhereBuilder;
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::WhereBuilder';

    sub can_build_where { my ($class, $where) = @_; ... }
    sub build_where     { my ($class, $where, $source, $dialect) = @_; ... return ($sql, \@binds) }

=head1 REQUIRED METHODS

=over 4

=item $bool = $builder->can_build_where($where)

True when this builder renders C<$where>. The chain asks each builder in
order until one says true, for every C<where> built, so keep it cheap.

=item ($sql, \@binds) = $builder->build_where($where, $source, $dialect)

The condition without the C<WHERE> keyword, or an empty string for none, and
its binds. Binds are C<[$field, $value]> pairs as
L<DBIx::QuickORM::Role::SQLBuilder> describes them. C<$source> is a
L<DBIx::QuickORM::Role::Source> and C<$dialect> a L<DBIx::QuickORM::Dialect>.

=back

=cut

requires qw/can_build_where build_where/;

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

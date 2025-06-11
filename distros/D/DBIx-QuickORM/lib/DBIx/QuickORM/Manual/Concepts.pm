package DBIx::QuickORM::Manual::Concepts;
use strict;
use warnings;

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Concepts - Important/Key concepts for
L<DBIx::QuickORM>.

=head1 DESCRIPTION

Knowing the basics about these concepts will help you understand how
DBIx::QuickORM does things.

=head1 DIALECTS

A dielect tell DBIx::QuickORM hwo to interact with and communicate with a
database. Not all SQL databases use identical syntax or extensions, a dialects
job to to define behaviors a specific database understands.

L<DBIx::QuickORM::Dialect> is the base class for dialects. All dialects should
subclass this base class.

It is important to pick the dialect that best matches your situation.
L<DBIx::QuickORM::Dialect::MySQL> may work for all flavors of MySQL, but
L<DBIx::QuickORM::Dialect::MySQL::MariaDB> will work much better if you are
using MariaDB, as the dialect will know about additions regular mysql does not
support.

=over 4

=item L<DBIx::QuickORM::Dialect::PostgreSQL>

For interacting with PostgreSQL databases.

=item L<DBIx::QuickORM::Dialect::SQLite>

For interacting with SQLite databases.

=item L<DBIx::QuickORM::Dialect::MySQL>

For interacting with generic MySQL databases.

=item L<DBIx::QuickORM::Dialect::MySQL::MariaDB>

For interacting with MariaDB databases.

=item L<DBIx::QuickORM::Dialect::MySQL::Percona>

For interacting with MySQL as distributed by Percona.

=item L<DBIx::QuickORM::Dialect::MySQL::Community>

For interacting with the Community Edition of MySQL.

=back

=head1 SCHEMA

This refers to L<DBIx::QuickORM::Schema>, your entire database schema/structure
should be represented in the ORM as a schema structure consisting of
L<DBIx::QuickORM::Schema::Table> objects, and others.

=head1 AFFINITY

Whenever you define a column in DBIx::QuickORM it is necessary for the ORM to
know the I<affinity> of the column. It may be any of these:

=over 4

=item C<string>

The column should be treated as a string when written to, or read from the
database.

=item C<numeric>

The column should be treated as a number when written to, or read from the
database.

=item C<boolean>

The column should be treated as a boolean when written to, or read from the
database.

=item C<binary>

The column should be treated as a binary data when written to, or read from the
database.

=back

Much of the time the affinity can be derived from other data. The
L<DBIx::QuickORM::Affinity> package has an internal map for default affinities
for many SQL types. Also if you use a class implementing
L<DBIx::QuickORM::Role::Type> it will often provide an affinity. You can
override the affinity if necessary. If the affinity cannot be derived you
must specify it.

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<http://github.com/exodist/DBIx-QuickORM/>.

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

See L<http://dev.perl.org/licenses/>

=cut

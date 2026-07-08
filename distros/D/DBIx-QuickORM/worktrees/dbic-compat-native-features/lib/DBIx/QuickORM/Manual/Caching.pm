package DBIx::QuickORM::Manual::Caching;
use strict;
use warnings;

our $VERSION = '0.000028';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Caching - How DBIx::QuickORM keeps one in-memory copy
of each row per connection.

=head1 DESCRIPTION

DBIx::QuickORM keeps at most one in-memory row object for any given database
row, per connection. This is sometimes called I<row caching>, I<dedup>, or
I<identity mapping>. This page explains what that guarantee means, how it
interacts with selects and modifications, and how to change or disable it.

For the broader picture see L<DBIx::QuickORM::Manual::Concepts> and the
documentation hub at L<DBIx::QuickORM::Manual>.

=head1 IDENTITY: ONE ROW OBJECT PER PRIMARY KEY

When you fetch the same database row twice through one connection, you get back
the I<same> Perl row object both times, not two copies of the same data:

    my $a = $handle->one(id => 1);
    my $b = $handle->one(id => 1);

    # Same object: $a and $b are identical references.

Because there is only ever one object for a given row, there is never a
question of which copy is current. Changes you make through one reference are
visible through every reference, and a relation that leads back to a row you
already hold returns the object you already have.

Identity is keyed on the row's B<primary key>. Sources without a primary key
cannot be deduplicated and are never cached.

=head1 PER-CONNECTION, NOT GLOBAL

The cache lives on the connection (L<DBIx::QuickORM::Connection>), held by its
row manager (L<DBIx::QuickORM::RowManager>). Two separate connections each have
their own cache, so the same database row loaded through two connections yields
two distinct objects. This is intentional: each connection has its own
transaction state and its own view of the data. See
L<DBIx::QuickORM::Manual::Connections> for the connection lifecycle.

=head1 WEAK REFERENCES: NO LEAKS

Cached rows are held by B<weak> reference. The cache lets you reuse a row while
it is still alive somewhere in your program, but it does not keep rows alive on
its own. Once nothing else references a row, it is garbage collected and its
cache entry disappears. Loading many rows and then dropping them does not grow
the cache without bound.

A consequence: identity is only guaranteed for as long as you hold a reference.
If you drop every reference to a row and fetch it again, you may get a fresh
object - but it will still be the only one, so the one-copy guarantee holds.

=head1 INTERACTION WITH SELECT / INSERT / UPDATE / DELETE

The row manager maintains the cache as part of each operation:

=over 4

=item select

A select first looks for the row in the cache by primary key. If found, the
existing object is returned (with its stored state refreshed); otherwise a new
object is created and cached.

=item insert

A newly inserted row is added to the cache under its primary key.

=item update

After an update the row stays cached. If the update changed the primary key,
the cache entry is moved from the old key to the new key so future lookups by
either value resolve correctly.

=item delete

A deleted row is removed from the cache.

=back

Invalidating a row (marking its data stale) also reaches the cached copy, so
the next access re-reads from the database.

=head1 THE DEFAULT MANAGER

Caching is provided by the connection's row manager. The default is
L<DBIx::QuickORM::RowManager::Cached>, which implements the per-primary-key,
weak-reference cache described above. The base class
L<DBIx::QuickORM::RowManager> does no caching at all - its cache hooks are
no-ops and C<does_cache> is false.

=head1 DISABLING OR OVERRIDING CACHING

To turn caching off, give the connection a plain
L<DBIx::QuickORM::RowManager> (or any manager whose C<does_cache> returns
false) as its C<manager>. With a non-caching manager every fetch builds a new
row object and the one-copy guarantee no longer applies.

To customise caching, supply your own manager - typically a subclass of
L<DBIx::QuickORM::RowManager::Cached> - via the connection's C<manager>
attribute, or build the ORM with a C<cache_class> so each connection it creates
gets a fresh cache of your chosen class.

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Manual>

The documentation hub.

=item L<DBIx::QuickORM::Manual::Concepts>

Key concepts that underpin the rest of the system.

=item L<DBIx::QuickORM::Manual::Connections>

The connection lifecycle that owns the cache.

=item L<DBIx::QuickORM::Connection>

The connection object.

=item L<DBIx::QuickORM::RowManager>

The base row manager and its cache hooks.

=back

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM/>.

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

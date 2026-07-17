package Dancer2::Plugin::ContentCache::Driver;
use v5.20;
use warnings;
use Moo::Role;

our $VERSION = '1.0000'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY

requires qw(
    has_aging_columns
    has_created_column
    create_entry
    find_entry
    delete_expired
);

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::ContentCache::Driver - Storage abstraction role for Dancer2::Plugin::ContentCache

=head1 VERSION

version 1.0000

=head1 SYNOPSIS

 package MyApp::ContentCache::Driver::Redis;
 use v5.20;
 use warnings;
 use Moo;

 with 'Dancer2::Plugin::ContentCache::Driver';

 has plugin => ( is => 'ro', required => 1, weak_ref => 1 );

 sub has_aging_columns { 1 }
 sub has_created_column { 1 }

 sub create_entry { my ($self, %entry) = @_; ... }
 sub find_entry   { my ($self, $uuid)  = @_; ... }
 sub delete_expired { my ($self) = @_; ... }

 1;

 # In config.yml:
 plugins:
   ContentCache:
     driver: MyApp::ContentCache::Driver::Redis

=head1 DESCRIPTION

L<Dancer2::Plugin::ContentCache> never talks to a database directly. Instead,
it delegates all storage operations to a small "driver" object that implements
this role. The bundled default is
L<Dancer2::Plugin::ContentCache::Driver::DBIC>, which stores cache entries
via L<DBIx::Class>. To use a different storage backend (Redis, a flat file,
another ORM, whatever you like), write a class that consumes this role and
point the C<driver> configuration option at it.

A driver class is instantiated as:

 $driver_class->new( plugin => $plugin, config => $plugin->config );

C<plugin> is the running L<Dancer2::Plugin::ContentCache> instance (handy if
you need L<< $plugin->app >> to reach other plugins), and C<config> is the
raw plugin configuration hashref, in case your driver needs its own settings.

=head1 REQUIRED METHODS

Any class that consumes this role B<must> implement the following methods.
The plugin never inspects storage internals itself; it only ever calls
these five methods.

=over 3

=item B<has_aging_columns>

Return a boolean indicating whether the backing store is capable of
recording both a creation time and an expiry time for an entry. If
C<cache_aging> is turned on in the plugin configuration and this method
returns false, C<Dancer2::Plugin::ContentCache> will C<croak> when the
application starts.

=item B<has_created_column>

Return a boolean indicating whether the backing store can record a creation
timestamp for an entry. This is independent of C<cache_aging>; a store may
track "created" without tracking "expiry".

=item B<create_entry>

 $driver->create_entry(
    uuid       => $uuid,
    data       => $data_as_string,
    metadata   => $metadata_as_json_string,
    created_dt => $created_dt,  # a DateTime object, or undef
    expiry_dt  => $expiry_dt,   # a DateTime object, or undef
 );

Persist a new, immutable cache entry. C<data> and C<metadata> are already
serialized to strings by the plugin; the driver need not know or care what
they mean, only that they must come back unchanged from C<find_entry>.

=item B<find_entry>

 my $entry = $driver->find_entry($uuid);

Given a UUID, return a hashref with keys C<uuid>, C<data>, C<metadata>,
C<created_dt>, and C<expiry_dt> (the latter two are C<DateTime> objects or
C<undef>, exactly as they were given to C<create_entry>), or return
C<undef> if no entry exists under that UUID. Note that C<find_entry> is not
responsible for enforcing expiry; the plugin itself decides whether an
entry found here is still valid.

=item B<delete_expired>

 my $count = $driver->delete_expired;

Delete all entries whose C<expiry_dt> has passed, and return the number of
entries removed. If the driver does not support aging, this should simply
return C<0>.

=back

=head1 SEE ALSO

=over 3

=item * L<Dancer2::Plugin::ContentCache>

=item * L<Dancer2::Plugin::ContentCache::Driver::DBIC>

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: Storage abstraction role for Dancer2::Plugin::ContentCache


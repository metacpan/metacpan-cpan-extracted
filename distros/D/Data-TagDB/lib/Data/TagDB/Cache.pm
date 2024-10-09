# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Cache;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.04;



sub db {
    my ($self) = @_;
    return $self->{db};
}


sub add {
    my ($self, @objects) = @_;
    my $c = $self->{objects};

    $c->{$_} = $_ foreach grep {defined} @objects;
}


sub clear {
    my ($self) = @_;

    # We just recreate the internal structures.
    # Droping them also drops the objects inside.

    $self->{objects} = {};
    $self->{by_key} = {};
}

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless \%opts, $pkg;

    $self->clear;

    return $self;
}

sub _add_by_key {
    my ($self, $owner, $type, $key, $object) = @_;

    $self->{by_key}{$owner} //= {};
    $self->{by_key}{$owner}{$type} //= {};
    $self->{by_key}{$owner}{$type}{$key} = $object;
    $self->add($object);
}

sub _get_by_key {
    my ($self, $owner, $type, $key) = @_;

    $self->{by_key}{$owner} //= {};
    $self->{by_key}{$owner}{$type} //= {};
    return $self->{by_key}{$owner}{$type}{$key};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Cache - Work with Tag databases

=head1 VERSION

version v0.04

=head1 SYNOPSIS

    use Data::TagDB;

    my Data::TagDB::Cache $cache = $db->create_cache;

Generic cache for L<Data::TagDB::Tag> objects.
Objects hold in a cache are kept available in a faster manner via L<Data::TagDB>'s interface.
Multiple cache objects can be created. A cached object is cleaned up once all references
(direct or via any cache object) are gone.

=head1 METHODS

=head2 db

    my Data::TagDB $db = $cache->db;

Returns the current L<Data::TagDB> object.

=head2 add

    $cache->add($tag0, $tag1, ...);

Adds any number of tags to the cache.
If any passed tag is C<undef> it is ignored. This allows to pass thins like C<$link-E<gt>context> without a manual check for C<undef>.

=head2 clear

    $cache->clear;

Clears the cache without destroying it. This is useful to clear caches owned by other objects.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

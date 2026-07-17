package Dancer2::Plugin::ContentCache::CacheEntry;
use v5.20;
use warnings;
use Moo;

our $VERSION = '1.0000'; # VERSION
our $AUTHORITY = 'cpan:GEEKRUTH'; # AUTHORITY

has uuid => (
    is       => 'ro',
    required => 1,
);

has data_format => (
    is       => 'ro',
    required => 1,
);

has data => (
    is       => 'ro',
    required => 1,
);

has created_dt => (
    is      => 'ro',
    default => sub { undef },
);

has expiry_dt => (
    is      => 'ro',
    default => sub { undef },
);

has metadata => (
    is      => 'ro',
    default => sub { {} },
);

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::ContentCache::CacheEntry - A single retrieved entry from the content cache

=head1 VERSION

version 1.0000

=head1 SYNOPSIS

 my $cache = retrieve_cache => $uuid;

 if ( $cache ) {
    send_as $cache->data_format => $cache->data;
 }

=head1 DESCRIPTION

Instances of this class are returned by the C<retrieve_cache> keyword of
L<Dancer2::Plugin::ContentCache>. It is a simple, read-only L<Moo> object;
see L<Dancer2::Plugin::ContentCache/"THE CACHE OBJECT"> for a description
of each attribute.

=head1 ATTRIBUTES

=head2 uuid

=head2 data_format

=head2 data

=head2 created_dt

=head2 expiry_dt

=head2 metadata

=head1 SEE ALSO

=over 3

=item * L<Dancer2::Plugin::ContentCache>

=back

=head1 AUTHOR

D Ruth Holloway <ruth@hiruthie.me>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by D Ruth Holloway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: A single retrieved entry from the content cache


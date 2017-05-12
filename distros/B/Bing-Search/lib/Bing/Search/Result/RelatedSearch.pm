package Bing::Search::Result::RelatedSearch;
use Moose;
extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';

with qw(
   Bing::Search::Role::Result::Url
   Bing::Search::Role::Result::Title
);

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::RelatedSearch - Related searches from Bing

=head1 METHODS

=over 3

=item C<Url>

A L<URI> object representing a new search related to the current
one.

=item C<Title>

The title of the related search, usually also the related search's
query.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.


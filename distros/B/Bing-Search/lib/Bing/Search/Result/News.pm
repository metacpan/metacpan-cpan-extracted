package Bing::Search::Result::News;
use Moose;

extends 'Bing::Search::Result';
with 'Bing::Search::Role::Types::DateType';
with 'Bing::Search::Role::Types::UrlType';

with qw(
      Bing::Search::Role::Result::Snippet
      Bing::Search::Role::Result::BreakingNews
      Bing::Search::Role::Result::Source
      Bing::Search::Role::Result::Url
      Bing::Search::Role::Result::Date
      Bing::Search::Role::Result::Title
);

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::News - News results from Bing

=head1 METHODS

=over 3

=item C<Snippet>

A snippet from the news article

=item C<BreakingNews>

A boolean indicating if the article is "breaking news"

=item C<Source>

The name of the source, i.e., "The Seattle Times"

=item C<Url>

A L<URI> objecting representing the link to the full article.

=item C<Date>

A L<DateTime> object representing the date of the article.

=item C<Title>

The title of the article.

=back

=head2 "NewsCollection" and "NewsRelated"

These two sub-groups are currently unimplemented.  Their data, if it exists, 
should remain accesible in the C<data> method.  See 
L<http://msdn.microsoft.com/en-us/library/dd250884.aspx> 
for details.  This will probably be added later, when I get around to it.

Unimplemented bits are:

=over3 

=item * NewsRelatedSearch/Url
=item * NewsRelatedSearch/Title
=item * NewsCollection/NewsArticles
=item * NewsCollection/Name

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

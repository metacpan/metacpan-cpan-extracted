package Bing::Search::Source::News;
use Moose;
extends 'Bing::Search::Source';

with 'Bing::Search::Role::NewsRequest::Count';

with qw(
Bing::Search::Role::SearchRequest::Market
Bing::Search::Role::SearchRequest::Version
Bing::Search::Role::SearchRequest::Options
Bing::Search::Role::NewsRequest::Offset
Bing::Search::Role::NewsRequest::LocationOverride
Bing::Search::Role::NewsRequest::Category
Bing::Search::Role::NewsRequest::SortBy
);

sub _build_source_name { 'News' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::News - Get news results

=head1 SYNOPSIS

 my $source = Bing::Search::Source::News->new;

=head1 DESCRIPTION

The News source fetches news articles given various criteria.

There is a special case, the "empty query", where Bing will return
the top news stories.  Otherwise, there are three options that interact
with each other.

From L<http://msdn.microsoft.com/en-us/library/dd250884.aspx>:

LocationOverride, Category, and SortBy are mutually exclusive. Specifically:

=over 3

=item * If LocationOverride is specified, then Category and SortBy, if 
specified, are ignored, and LocationOverride is used.

=item * If LocationOverride is not specified, and Category is specified, 
the SortBy, if specified, is ignored, and Category is used.

=item * If neither LocationOverride nor Category is specified, and 
SortBy is specified, then SortBy is used.

=back 

=head1 METHODS

Make sure to read the previous section with regards to C<LocationOverride>, 
C<Category>, and C<SortBy>.

=over 3

=item C<Market>, C<Version>, C<Options>, and C<setOptions>

See L<Bing::Search> for documentation on these common attributes.

=item C<News_Count> and C<News_Offset> retain the familiar interaction as well.

The default value for C<News_Count> is 10, with a range of 1 to 15.  The sum of 
C<News_Count> and C<News_Offset> cannot exceed 15.  C<News_Offset> must be 0 or
greater.

=item C<News_LocationOverride>

Overrides the location for news.  If invalid, the default location is used ("everywhere").

The format is B<US>.<I<state>> and is only valid in the en-US market.

=item C<News_Category>

Filters results based on a category.  Only valid in the en-US market.  According
to L<http://msdn.microsoft.com/en-us/library/dd250868.aspx>, valid values are:

=over 3

=item rt_Business

=item rt_Entertainment

=item rt_Health

=item rt_Politics

=item rt_Sports

=item rt_US

=item rt_World

=item rt_ScienceAndTechnology

=back

=item C<News_SortBy>

How to sort the news results.  Valid options are B<Date> and B<Relevance>.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it
under the same terms as Perl itself.

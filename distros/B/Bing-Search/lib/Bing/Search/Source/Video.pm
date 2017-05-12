package Bing::Search::Source::Video;
use Moose;
extends 'Bing::Search::Source';

with 'Bing::Search::Role::VideoRequest::Count';

with qw(
Bing::Search::Role::SearchRequest::Market
Bing::Search::Role::SearchRequest::Version
Bing::Search::Role::SearchRequest::Adult
Bing::Search::Role::SearchRequest::Options
Bing::Search::Role::VideoRequest::Offset
Bing::Search::Role::VideoRequest::Filter
Bing::Search::Role::VideoRequest::SortBy
);

sub _build_source_name { 'Video' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::Video - Video search with Bing

=head1 METHODS

=over 3

=item C<Market>, C<Version>, C<Adult>, C<Options>, and C<setOptions>

See L<Bing::Search> for documentation of these common attributes.

=head1 C<Video_Offset> and C<Video_Count>

The default value for C<Video_Count> is 10, with a possible range of 1 to 50.  

The sum of C<Video_Offset> and C<Video_Count> may not exceed 1,000.  

=item C<Video_Filter>

Contains an arrayref of filters.  Don't fiddle with tis.  Use C<Video_setFilter>
instead.

=item C<Video_setFilter>

Provide the name of a filter, optionally with a C<+> to add it.  Prepend a C<-> 
to instead remove the filter.

A list of filters is available here: L<http://msdn.microsoft.com/en-us/library/dd560956.aspx>.

=item C<Video_SortBy>

Sort the results.  Valid options are B<Date> or B<Relevance>.

=back

=head1 AUTHOR

Dave Houston L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

package Bing::Search::Result::MobileWeb;
use Moose;

extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::DateType';
with 'Bing::Search::Role::Types::UrlType';

with 'Bing::Search::Role::Result::DateTime';
with 'Bing::Search::Role::Result::Description';
with 'Bing::Search::Role::Result::DisplayUrl';
with 'Bing::Search::Role::Result::Title';
with 'Bing::Search::Role::Result::Url';

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::MobileWeb - Get mobile web search resulsts

=head1 METHODS

=over 3

=item C<DateTime>

Returns a L<DateTime> object representing the date and time of the last
crawl.

=item C<Description>

A string containing a portion of the HTML from the page.

=item C<DisplayUrl>

A L<URI> object containing the URL, possibly modified for display,
for the page.

=item C<Title>

The contents of the <title> tag.  

=item C<Url>

A L<URI> object containing the unaltered URL.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

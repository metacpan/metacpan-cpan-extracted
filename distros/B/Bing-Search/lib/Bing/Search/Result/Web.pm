package Bing::Search::Result::Web;
use Moose;
extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';
with 'Bing::Search::Role::Types::DateType';

with qw(
   Bing::Search::Role::Result::Url
   Bing::Search::Role::Result::CacheUrl
   Bing::Search::Role::Result::DateTime
   Bing::Search::Role::Result::Description
   Bing::Search::Role::Result::DisplayUrl
   Bing::Search::Role::Result::Title
);

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::Web - Web results from Bing

=head1 METHODS

=over 3

=item C<Url>

A L<URI> object representing the link to the result

=item C<CacheUrl>

A L<URI> representing Bing's cache of the result.

=item C<DateTime>

A L<DateTime> object representing the date and time of Bing's
last crawl.

=item C<Description>

A portion of the body text of the result.

=item C<DisplayUrl>

A L<URI> object representing the link to the result, possibly
modified for display.

=item C<Title>

The title of the result.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under 
the same terms as Perl itself.



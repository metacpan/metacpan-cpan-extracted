package Bing::Search::Source::Image;
use Moose;
extends 'Bing::Search::Source';

with 'Bing::Search::Role::ImageRequest::Count';

with qw(
Bing::Search::Role::SearchRequest::Market
Bing::Search::Role::SearchRequest::Adult
Bing::Search::Role::SearchRequest::Version
Bing::Search::Role::SearchRequest::Options
);

with qw(
Bing::Search::Role::ImageRequest::Offset
Bing::Search::Role::ImageRequest::Filter
);

sub _build_source_name { 'Image' }

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Source::Image - Image search for Bing::Search

=head1 SYNOPSIS

 my $source = Bing::Search::Source::Image->new(
   Market => 'en-US',
   Count => 1
 );
  
=head1 METHODS

=over 3

=item C<Market>, C<Adult>, C<Version>, C<Options>, C<setOptions>

See L<Bing::Search> for details on these common methods.

=item C<Image_Count>

Indicates how many results to return.

=item C<Image_Offset>

Indicates on which result to start.  An value of '2', coupled with a 
C<Count> of '10' would fetch results 2 through 12.  

=item C<Image_Filter>

Returns the list of current filters.  You may attempt to set the filters 
yourself this way, keeping in mind the filters are simply an arrayref.  

Using the C<setImage_Filter> method is the reccomended way to change
the filters.

See L<http://msdn.microsoft.com/en-us/library/dd560913.aspx> for details on 
which filters are currently available.  Please note that, at the time
of this writing, 'Size:Height:<Height>' and 'Size:Width:<Width>' filters
are not implemented.  

=item C<setImage_Filter>

Changes the image filters.  The syntax is easy.  Prepend a - to the name
of a filter to remove it.  Name it or prepend a + to add it.  

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=headd1 LICENSE

This library is free software; you may redistribute and/or modify it under the 
same terms as Perl itself.

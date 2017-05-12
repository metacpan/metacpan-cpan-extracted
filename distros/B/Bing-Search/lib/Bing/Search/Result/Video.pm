package Bing::Search::Result::Video;
use Moose;
use Bing::Search::Result::Video::StaticThumbnail;

extends 'Bing::Search::Result';

with 'Bing::Search::Role::Types::UrlType';
with 'Bing::Search::Role::Types::DurationType';

with qw(
   Bing::Search::Role::Result::Title
   Bing::Search::Role::Result::SourceTitle
   Bing::Search::Role::Result::PlayUrl
   Bing::Search::Role::Result::RunTime
   Bing::Search::Role::Result::ClickThroughPageUrl
);

has 'StaticThumbnail' => ( is => 'rw', isa => 'Bing::Search::Result::Video::StaticThumbnail' );

before '_populate' => sub { 
   my $self = shift;
   my $data = $self->data;
   my $t = Bing::Search::Result::Video::StaticThumbnail->new;
   my $thumb = delete $data->{StaticThumbnail};
   $t->data( $thumb );
   $t->_populate();
   $self->StaticThumbnail( $t );
};

__PACKAGE__->meta->make_immutable;

=head1 NAME

Bing::Search::Result::Video - Video search results

=head1 METHODS

=over 3

=item C<Title>

The name of the video.

=item C<SourceTitle>

The name of the video's source, ie, "Dailymotion" or "YouTube".

=item C<PlayUrl>

A L<URI> object representing a link to the original video file, if
available.

=item C<RunTime>

A L<DateTime::Duration> object representing the video's play time.

=item C<ClickThroughPageUrl>

A L<URI> object representing a link to play the video via Bing's 
"Video" page.

=item C<StaticThumbnail>

A L<Bing::Search::Result::Video::StaticThumbnail> object, 
representing a static image thumbnail of the video.

=back

=head1 AUTHOR

Dave Houston, L< dhouston@cpan.org >, 2010

=head1 LICENSE

This library is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

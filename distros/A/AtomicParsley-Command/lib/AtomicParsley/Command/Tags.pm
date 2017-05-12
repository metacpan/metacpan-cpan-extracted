use strict;
use warnings;

package AtomicParsley::Command::Tags;
$AtomicParsley::Command::Tags::VERSION = '1.153400';
# ABSTRACT: represent the mp4 metatags

use Object::Tiny qw{
  artist
  title
  album
  genre
  tracknum
  disk
  comment
  year
  lyrics
  composer
  copyright
  grouping
  artwork
  bpm
  albumArtist
  compilation
  advisory
  stik
  description
  longdesc
  TVNetwork
  TVShowName
  TVEpisode
  TVSeasonNum
  TVEpisodeNum
  podcastFlag
  category
  keyword
  podcastURL
  podcastGUID
  purchaseDate
  encodingTool
  gapless
};

sub prepare {
    my $self = shift;

    # loop through all accessors and generate parameters for AP
    my @out;
    while ( my ( $key, $value ) = each(%$self) ) {
        next unless ( defined $value );

        push @out, "--$key";
        push @out, $value;
    }

    return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AtomicParsley::Command::Tags - represent the mp4 metatags

=head1 VERSION

version 1.153400

=head1 SYNOPSIS

  my $tags = AtomicParsley::Command::Tags->new(%tags);

=head1 ATTRIBUTES

=head2 artist

=head2 title

=head2 album

=head2 genre

=head2 tracknum

=head2 disk

=head2 comment

=head2 year

=head2 lyrics

=head2 composer

=head2 copyright

=head2 grouping

=head2 artwork

=head2 bpm

=head2 albumArtist

=head2 compilation

=head2 advisory

=head2 stik

=head2 description

=head2 longdesc

=head2 TVNetwork

=head2 TVShowName

=head2 TVEpisode

=head2 TVSeasonNum

=head2 TVEpisodeNum

=head2 podcastFlag

=head2 category

=head2 keyword

=head2 podcastURL

=head2 podcastGUID

=head2 purchaseDate

=head2 encodingTool

=head2 gapless

=head1 METHODS

=head2 prepare

Prepares the tags into an array suitable for passing to AtomicParsley via L<IPC::Cmd>.

=head1 SEE ALSO

=over 4

=item *

L<AtomicParsley::Command>

=back

=head1 AUTHOR

Andrew Jones <andrew@arjones.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Andrew Jones.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

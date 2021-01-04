#
# $Id$
#

=head1 NAME

AudioFile::Info::MP3::Tag - Perl extension to get info from MP3 files.

=head1 DESCRIPTION

This is a plugin for AudioFile::Info which uses MP3::Tag to get or set
data about MP3 files.

See L<AudioFile::Info> for more details.

=cut

package AudioFile::Info::MP3::Tag;

use 5.006;
use strict;
use warnings;
use Carp;

use MP3::Tag;

our $VERSION = '1.6.3';

my %data = (artist => ['artist', 'TPE1'],
            title  => ['song', 'TIT2'],
            album  => ['album', 'TALB'],
            track  => ['track', 'TRCK'],
            year   => ['year', 'TYER'],
            genre  => ['genre', 'TCON']);

sub new {
  my $class = shift;
  my $file = shift;
  my $obj = MP3::Tag->new($file);
  $obj->get_tags;

  bless { obj => $obj }, $class;
}

sub DESTROY {
  my $file = $_[0]->{obj}{ID3v2}{mp3} || $_[0]->{obj}{ID3v2}{mp3};

  $file->close if defined $file;
}

sub AUTOLOAD {
  our $AUTOLOAD;

  my ($pkg, $sub) = $AUTOLOAD =~ /(.+)::(\w+)/;

  die "Invalid attribute $sub" unless exists $data{$sub};

  if ($_[1]) {
    $_[0]->{obj}->new_tag('ID3v1') unless $_[0]->{obj}{ID3v1};
    $_[0]->{obj}->new_tag('ID3v2') unless $_[0]->{obj}{ID3v2};
    if (my $frame = $_[0]->{obj}{ID3v1}) {
      my $tag = $data{$sub}[0];
      $frame->$tag($_[1]);
      $frame->write_tag;
    }
    if (my $frame = $_[0]->{obj}{ID3v2}) {
      my $tag = $data{$sub}[1];
      if (exists $frame->get_frame_ids->{$tag}) {
        $frame->change_frame($tag, $_[1]);
      } else {
        $frame->add_frame($tag, $_[1]);
      }
      $frame->write_tag;
    }
  }

  if ($_[0]->{obj}{ID3v2}) {
    return ($_[0]->{obj}{ID3v2}->get_frame($data{$sub}[1]))[0];
  }
  if ($_[0]->{obj}{ID3v1}) {
    my $tag = $data{$sub}[0];
    return $_[0]->{obj}{ID3v1}->$tag;
  }
  return;
}


1;
__END__

=head1 METHODS

=head2 new

Creates a new object of class AudioFile::Info::MP3::Tag. Usually called
by AudioFile::Info::new.

=head1 AUTHOR

Dave Cross, E<lt>dave@mag-sol.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2009 by Magnum Solutions Ltd. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

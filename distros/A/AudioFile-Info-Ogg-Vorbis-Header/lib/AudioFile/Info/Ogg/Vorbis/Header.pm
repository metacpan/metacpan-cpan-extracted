
=head1 NAME

AudioFile::Info::Ogg::Vorbis::Header - Perl extension to get info from
Ogg Vorbis files.

=head1 DESCRIPTION

Extracts data from an Ogg Vorbis file using the CPAN module
Ogg::Vorbis::Header.

See L<AudioFile::Info> for more details.

=cut

package AudioFile::Info::Ogg::Vorbis::Header;

use 5.006;
use strict;
use warnings;
use Carp;

use Ogg::Vorbis::Header;
# nasty Inline kludge
# needed as this module is never "used", only "required"
require Inline;
Inline->init;

our $VERSION = '1.8.3';

my %data = (artist => 'ARTIST',
            title  => 'TITLE',
            album  => 'ALBUM',
            track  => 'TRACKNUMBER',
            year   => 'DATE',
            genre  => 'GENRE');

sub new {
  my $class = shift;
  my $file = shift;
  my $obj = Ogg::Vorbis::Header->new($file);

  bless { obj => $obj }, $class;
}

sub DESTROY {}

sub AUTOLOAD {
  our $AUTOLOAD;

  my ($pkg, $sub) = $AUTOLOAD =~ /(.*)::(\w+)/;

  croak "Invalid attribute '$sub'" unless $data{$sub};

  if ($_[1]) {
    my @matches = grep { $_ eq $data{$sub} } $_[0]->{obj}->comment_tags;
    if (@matches) {
      $_[0]->{obj}->edit_comment($data{$sub}, $_[1]);
    } else {
      $_[0]->{obj}->add_comments($data{$sub}, $_[1]);
    }
    $_[0]->{obj}->write_vorbis;
  }

  return ($_[0]->{obj}->comment($data{$sub}))[0];
}

1;
__END__

=head1 METHODS

=head2 new

Creates a new object of class AudioFile::Info::Ogg::Vorbis::Header. Usually
called by AudioFile::Info::new.

=head1 AUTHOR

Dave Cross, E<lt>dave@dave.org.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Dave Cross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

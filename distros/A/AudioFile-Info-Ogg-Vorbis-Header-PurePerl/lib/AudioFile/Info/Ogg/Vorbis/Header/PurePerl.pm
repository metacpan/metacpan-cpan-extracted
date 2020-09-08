=head1 NAME

AudioFile::Info::Ogg::Vorbis::Header::PurePerl - Perl extension to get
info from Ogg Vorbis files.

=head1 DESCRIPTION

Extracts data from an Ogg Vorbis file using the CPAN module
Ogg::Vorbis::Header::PurePerl.

See L<AudioFile::Info> for more details.

=cut

package AudioFile::Info::Ogg::Vorbis::Header::PurePerl;

use 5.006;
use strict;
use warnings;
use Carp;

use Ogg::Vorbis::Header::PurePerl;

our $VERSION = '1.5.2';

my %data = (artist => 'ARTIST',
            title  => 'TITLE',
            album  => 'ALBUM',
            track  => 'TRACKNUMBER',
            year   => 'DATE',
            genre  => 'GENRE');

sub new {
  my $class = shift;
  my $file = shift;
  my $obj = Ogg::Vorbis::Header::PurePerl->new($file);

  bless { obj => $obj }, $class;
}

sub DESTROY {}

sub AUTOLOAD {
  our $AUTOLOAD;

  my ($pkg, $sub) = $AUTOLOAD =~ /(.*)::(\w+)/;

  die "Invalid attribute $sub" unless $data{$sub};

  return ($_[0]->{obj}->comment($data{$sub}))[0];
}


1;
__END__

=head1 METHODS

=head2 new

Creates a new object of class AudioFile::Info::MP3::ID3Lib. Usually called
by AudioFile::Info::new.

=head1 AUTHOR

Dave Cross, E<lt>dave@perlhacks.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Dave Cross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

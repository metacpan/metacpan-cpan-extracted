=head1 NAME

AudioFile::Info::MP3::Info - Perl extension to get info from MP3 files.

=head1 DESCRIPTION

This is a plugin for AudioFile::Info which uses MP3::ID3Lib to get
data about MP files.

See L<AudioFile::Info> for more details.

=cut

package AudioFile::Info::MP3::Info;

use 5.006;
use strict;
use warnings;
use Carp;

use MP3::Info;

our $VERSION = '1.4.2';

my %data = (artist => 'ARTIST',
            title  => 'TITLE',
            album  => 'ALBUM',
            track  => 'TRACKNUM',
            year   => 'YEAR',
            genre  => 'GENRE');

sub new {
  my $class = shift;
  my $file = shift;
  my $obj = MP3::Info->new($file);

  bless { obj => $obj }, $class;
}

sub DESTROY {}

sub AUTOLOAD {
  my $self = shift;

  our $AUTOLOAD;

  my ($pkg, $sub) = $AUTOLOAD =~ /(.+)::(\w+)/;

  die "Invalid attribute $sub" unless exists $data{$sub};

  return $self->{obj}->{$data{$sub}};
}


1;
__END__

=head1 METHODS

=head2 new

Creates a new object of class AudioFile::Info::MP3::Info. Usually called
by AudioFile::Info::new.

=head1 AUTHOR

Dave Cross, E<lt>dave@dave.org.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Dave Cross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#
# $Id: $
#

=head1 NAME

AudioFile::Info::MP4::Info - Perl extension to get info from MP4 files.

=head1 DESCRIPTION

Extracts data from an MP4 file using the CPAN module
MP4::Info.

See L<AudioFile::Info> for more details.

=cut 

package AudioFile::Info::MP4::Info;

use 5.006;
use strict;
use warnings;
use Carp;

use MP4::Info;

our $VERSION = "0.6";

my %data = (artist => ['ART',      'ARTIST'],
            title  => ['NAM',      'TITLE'],
            album  => ['ALB',      'ALBUM'],
            track  => ['TRACKNUM', 'TRKN'],
            year   => ['DATE',     'YEAR'],
            genre  => ['GNRE',     'GENRE']);

sub new {
  my $class = shift;
  my $file  = shift;
  my $obj   = get_mp4tag($file) || die "Couldn't get MP4 info for $file";
  bless { obj => $obj }, $class;
}

sub DESTROY {}

sub AUTOLOAD {
  our $AUTOLOAD;

  my ($pkg, $sub) = $AUTOLOAD =~ /(.*)::(\w+)/;

  die "Invalid attribute $sub" unless $data{$sub};
  foreach my $try (@{$data{$sub}}) {
    return $_[0]->{obj}->{$try} if defined $_[0]->{obj}->{$try};
  }
  return undef;
}


1;
__END__

=head1 METHODS

=head2 new

Creates a new object of class AudioFile::Info::MP4::Info. Usually called
by AudioFile::Info::new.

=head1 AUTHOR

Simon Wistow, E<lt>simon@thegestalt.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 by Simon Wistow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


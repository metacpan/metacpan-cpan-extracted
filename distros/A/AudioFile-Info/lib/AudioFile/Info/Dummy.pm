=head1 NAME

AudioFile::Info::Dummy

=head1 DESCRIPTION

Dummy plugin for testing AudioFile::Info.

=head1 SYNOPSIS

Don't use this.

=cut

package AudioFile::Info::Dummy;

use 5.006;
use strict;
use warnings;

=head1 METHODS

=head2 new, artist, title, album, track, year, genre

=cut

sub new {
  return bless {}, $_[0];
}

sub artist { return 'ARTIST' }
sub title  { return 'TITLE'  }
sub album  { return 'ALBUM'  }
sub track  { return 0        }
sub year   { return 'YEAR'   }
sub genre  { return 'GENRE'  }

1;


package CDDB::File;

$VERSION = '1.05';

=head1 NAME

CDDB::File - Parse a CDDB/freedb data file

=head1 SYNOPSIS

  my $disc = CDDB::File->new("rock/f4109511");

  print $disc->id, $disc->all_ids;
  print $disc->artist, $disc->title;
  print $disc->year, $disc->genre, $disc->extd;
  print $disc->length, $disc->track_count;
  
  print $disc->revision, $disc->submitted_via, $disc->processed_by;

  foreach my $track ($disc->tracks) {
    print $track->number, $track->title, $track->artist;
    print $track->length, $track->extd;
  }

=head1 DESCRIPTION

This module provides an interface for extracting data from CDDB-format
data files, as used by freedb.

It does not read data from your CD, or submit information to freedb.

=head1 METHODS

=head2 new

  my $disc = CDDB::File->new("rock/f4109511");

This will create a new object representing the data in the file name
specified.

=head2 id / all_ids

  my $discid = $disc->id;
  my @discid = $disc->all_ids;

Due to how freedb works, one CD may have several IDs associated with
it. 'id' will return the first of these (not necessarily related to the
filename from which this was read), whilst 'all_ids' will return all
of them.

=head2 title / artist

The title and artist of this CD. For eponymous CDs these will be
identical, even if the data file leaves the artist field blank.

=head2 year 

The (4-digit) year of release. 

=head2 genre 

The genre of this CD. This is the genre as stored in the data file itself,
which is not related to the 11 main freedb genres.

=head2 extd

The "extended data" for the CD. This is used for storing miscellaneous
information which has no better storage place, and can be of any length.

=head2 length

The run time of the CD in seconds.

=head2 track_count

The number of tracks on the CD.

=head2 revision

Each time information regarding the CD is updated this revision number
is incremented. This returns the revision number of this version.

=head2 processed_by / submitted_via 

The software which submitted this information to freedb and which
processed it at the other end.

=head2 tracks

  foreach my $track ($disc->tracks) {
    print $track->number, $track->title, $track->artist;
    print $track->length, $track->extd;
  }

Returns a list of Track objects, each of which knows its number (numering
from 1), title, length (in seconds), offset, and may also have extended
track data.

Tracks may also contain an 'artist' field. If this is not set the artist
method will return the artist of the CD.

=cut

use strict;
use IO::File;

sub new {
  my ($class, $file) = @_;
  my $fh = new IO::File $file, "r" or die "Can't read $file\n";
  chomp(my @data = <$fh>);
  bless {
    _data => \@data,
  }, $class;
}

sub _data { @{shift->{_data}} }

sub id            { (shift->all_ids)[0]                     }
sub all_ids       { split /,/, shift->_get_lines("DISCID=") }
sub year          { shift->_get_lines("DYEAR=")             }
sub genre         { shift->_get_lines("DGENRE=")            }
sub extd          { shift->_get_lines("EXTD=")              }
sub revision      { shift->_get_lines("# Revision: ")       }
sub submitted_via { shift->_get_lines("# Submitted via: ")  }
sub processed_by  { shift->_get_lines("# Processed by: ")   }

sub _offsets {
  my $self = shift;
  my $from = $self->_offset_line;
  ((grep s/^#\s*//, ($self->_data)[$from + 1 .. $from + $self->track_count]), 
   $self->length * 75);
}

sub _offset_line {
  my $self = shift;
  my @data = $self->_data;
  foreach (0 .. $#data) {
    return $_ if $data[$_] =~ /^# Track frame offsets/;
  }
  return 2;
}

sub length     { 
  my $length = shift->_get_lines("# Disc length: ");
     $length =~ s/ sec(ond)?s//;
  return $length;
}

sub _title_line { 
  my $self = shift;
  $self->{_title_line} ||= $self->_get_lines("DTITLE=") 
}

sub _split_title {
  my $self = shift;
  ($self->{_artist}, $self->{_title}) = split /\s+\/\s+/, $self->_title_line, 2;
  $self->{_title} ||= $self->{_artist};
}

sub title {
  my $self = shift;
  $self->_split_title unless defined $self->{_title};
  $self->{_title};
}

sub artist {
  my $self = shift;
  $self->_split_title unless defined $self->{_artist};
  $self->{_artist};
}

sub tracks { 
  my $self = shift;
  my @title  = $self->_get_multi_lines("TTITLE");
  my @extd   = $self->_get_multi_lines("EXTT");
  my @offset = $self->_offsets;
  return map {
    bless { 
      _cd     => $self,
      _number => $_+1,
      _tline  => $title[$_],
      _extd   => $extd[$_],
      _offset => $offset[$_],
      _length => int(($offset[$_+1] - $offset[$_]) / 75),
    }, 'CDDB::File::Track'
  } 0 .. $self->_highest_track_no;
}

sub _get_lines {
  my ($self, $keyword) = @_;
  join "", grep s/^${keyword}//, $self->_data;
}

sub _get_multi_lines {
  my ($self, $keyword) = @_;
  map $self->_get_lines("${keyword}$_="), 0 .. $self->_highest_track_no;
}

sub _highest_track_no { 
  my $self = shift;
  $self->{_high} ||= pop @{[ map /^TTITLE(\d+)=/, $self->_data ]}
}

sub track_count { shift->_highest_track_no + 1 }

# ==================================================================== #

package CDDB::File::Track;

use overload 
  '""'  => 'title';

sub cd     { shift->{_cd} }
sub extd   { shift->{_extd}  }
sub length { shift->{_length}}
sub number { shift->{_number}}
sub offset { shift->{_offset}}

sub _split_title {
  my $self = shift;
  if ($self->cd->artist eq "Various") {
    ($self->{_artist}, $self->{_title}) = split /\s+\/\s+/, $self->{_tline}, 2
  } else {
    $self->{_title}  = $self->{_tline};
    $self->{_artist} = $self->cd->artist;
  }

  unless ($self->{_title}) {
    $self->{_title} = $self->{_artist};
    $self->{_artist} = $self->cd->artist;
  }
}

sub title {
  my $self = shift;
  $self->_split_title unless defined $self->{_title};
  $self->{_title};
}

sub artist {
  my $self = shift;
  $self->_split_title unless defined $self->{_artist};
  $self->{_artist};
}

1;

=head1 SEE ALSO

http://www.freedb.org/

=head1 AUTHOR

Tony Bowden

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-CDDB-File@rt.cpan.org

=head1 COPYRIGHT

  Copyright (C) 2001-2005 Tony Bowden. All rights reserved.

  This program is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License; either version 2 of the License,
  or (at your option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.


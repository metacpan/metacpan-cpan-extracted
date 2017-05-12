package Audio::DB::Reports;
# $Id: Reports.pm,v 1.2 2005/02/27 16:56:25 todd Exp $

# THIS MODULE SHOULD REALLY ONLY HOLD COLLECTIVE METHODS THAT GENERATE REPORTS

use strict 'vars';
use Carp 'croak','cluck';
use CGI qw/:standard *table *TR -no_xhtml *center/;
use DBI;
use vars qw(@ISA $VERSION);

use Audio::DB;
use Audio::DB::Query;
use Audio::DB::Util::Warnings;
use Audio::DB::Util::DataAccess;
use Audio::DB::Util::Rearrange;

@ISA = qw/
  Audio::DB
  Audio::DB::Query 
  Audio::DB::Util::DataAccess
  Audio::DB::Util::Warnings/;

$VERSION = '';

=pod

=head1 NAME

Audio::DB::Reports - Generate quick reports of a Audio::DB database

=head1 SYNOPSIS

use Audio::DB::Reports;

my $report = Audio::DB::Reports->new(-dsn => 'musicdb');

my $albums = $report->album_list(-sort_by => 'artist');
foreach my $album_obj (@$albums) {
  my $album   = $album_obj->album;
  my $artist  = $album_obj->artists;
  my $year    = $album_obj->years;

  print join("\t",$album,$artist,$year),"\n";

=head1 OVERVIEW

Audio::DB::Reports facilitates several different classes of reports.
These include full library reports, song, artist, album, genre and
bitrate based reports.  In general, each report returns arrays of the
appropriate objects.

Associated accessor methods are provide full access to the underlying
data.

=cut

#############################
#   ALBUM REPORTS
#############################

=pod

=head2 Album Reports

Album reports aggregate songs into albums provide quick, decise views
of your collection. These include:

    - listing all albums with associated artists and year released
    - finding albums that fall below a given bitrate threshold
    - finding albums with multiple bitrates

The following methods return a complex data structure. It is suggested
that you use provided methods to access the structure as it may change
in future releases.

=over 4

=item $report->album_list(@options);

Generate a list of all albums. Returns a list of Audio::DB::Album
objects, each potentially containing Audio::DB::Song objects.

 Options:
   -sort_order    A sort key. One of artist, album, or year
   -include_songs Boolean true to return songs with the albums

The resulting list can be sorted by artist, album, or year released by
passing the sort_order option.  In the event that multiple years or
artists are contained on the album, the placeholder "Various Artists"
or "Various Years" will be used as the search key.

In the interests of memory consumption, the album_list() method
returns only the album name, artist, year, and bitrates for each album
by default.  If you also need access to the song list for each
individual album, pass a true value with the -include_songs option.

=cut

# The internal data strcuture for album reports looks like this
#
#  $self = [ {
#                 album    => album name,
#                 album_id => album id,
#                 artists  => [ all contributing artists ],
#                 songs    => [ all contributing songs   ],
#                 bitrates => [ bitrates seen for the album ],
#	  	  years    => [ years seen for the album ],
# Also included in the hash ref but not necessarily accurate because of compilation CDs
#                 year     => year released
#                 artist   => primary artist
#               } ]
#


sub album_list {
  my ($self,@p) = @_;
  my ($sort_by,$include) = rearrange([qw/SORT_BY INCLUDE/],@p);
  my $albums = $self->fetch_class(-class=>'albums');
  my %include = map {$_ => 1 } @$include;
  if (defined $include{songs}) {
    foreach my $album (@$albums) {
      my $songs = $self->fetch(-class=>'song',-query=>$album->album_id,-perspective=>'by_album_id');
      $album->add_songs($songs);
    }
  }

  if ($sort_by) {
    my @sorted = _sort_albums($sort_by,$albums);
    return \@sorted;
  }
  return $albums;
}

=pod

=item $report->albums_with_multiple_bitrates(@options)

Display all albums that have songs of different bitrates. Returns a
list of Audio::DB::Album objects, each potentially containing
Audio::DB::Song objects.

 Options:
   -sort_order      A sort key. One of artist, album, or year
   -include_songs   Boolean true to return songs with the albums

Like album_list(), returned albums can be sorted by passing the
sort_order option, and can contain songs if passed the -include_songs
option.  See album_list() for details.

=cut

sub albums_with_multiple_bitrates {
  my ($self,@p) = @_;
  my ($sort_by) = rearrange([qw/SORT_BY/],@p);
  my $adaptor = $self->adaptor;

  my $albums = $self->fetch_class(-class=>'album');
  foreach my $album (@$albums) {
    my $songs = $self->fetch(-class=>'song',-query=>$album->album_id,-perspective=>'by_album_id');
    $album->add_songs($songs);
  }

  my @retain;
  foreach (@$albums) {
    my $bitrate = $_->bitrates;
    next unless $bitrate eq 'various';
    push @retain,$_;
  }

  if ($sort_by) {
    my @sorted = _sort_albums($sort_by,\@retain);
    return \@sorted;
  }
  return \@retain;
}


=pod

=item $report->albums_below_bitrate_threshold(@options)

Display all albums that have ANY songs below a provided bitrate
threshold.  Returns a list of Audio::DB::Album objects, each
potentially containing Audio::DB::Song objects.

 Options:
   -threshold     The bitrate threshold
   -sort_order    A sort key. One of artist, album, or year
   -include_songs Boolean true to return songs with the albums

Like album_list(), returned albums can be sorted by passing the
sort_order option, and can contain songs if passed the -include_songs
option.  See album_list() for details.

=cut


# ATTEMPTING TO OPTIMIZE...
#sub albums_below_bitrate_threshold {
#  my ($self,@p) = @_;
#  my ($threshold,$sort_by,$include_songs) = rearrange([qw/THRESHOLD SORT_BY INCLUDE_SONGS/],@p);
#  my $adaptor = $self->adaptor;
#  my $sth = $adaptor->prepare('albums_below_bitrate_threshold');
#  $sth->execute($threshold);
#  my @return;
#  while (my $h = $sth->fetchrow_hashref) {
#    # Create new album objects for each
#    my $obj = Audio::DB::DataTypes::Album->new(-adaptor=>$adaptor,-data=>$h);
#    my $id = $obj->album_id;
#    # Need to touch songs to get artists and bitrates (could use seperate queries, too).
#    my $songs = $self->fetch_songs(-album=>$id);
#    @{$obj->{songs}} = @$songs if ($include_songs);  # Stuff in the songs, too, if requested
#    my %seen;
#    push(@{$obj->{artists}},grep { !$seen{$_}++} map { $_->artist  } @$songs);
#    push(@{$obj->{artists}},grep { !$seen{$_}++} map { $_->bitrate } @$songs);
#    push @return,$obj;
#  }
#  return \@return;
#}


sub albums_below_bitrate_threshold {
  my ($self,@p) = @_;
  my ($threshold,$sort_by,$include) = rearrange([qw/THRESHOLD SORT_BY INCLUDE/],@p);
  $include = [qw/songs/] unless @$include;  # We need to add in the songs in order to fetch all bitrates
  my $albums  = $self->fetch_class(-class=>'albums');
  my %include = map {$_ => 1 } @$include;
  if (defined $include{songs}) {
    foreach my $album (@$albums) {
      my $songs = $self->fetch(-class=>'song',-query=>$album->album_id,-perspective=>'by_album_id');
      $album->add_songs($songs);
    }
  }

  my @retain;
  foreach (@$albums) {
    my $bitrate = $_->bitrates;
    unless ($bitrate eq 'various') {
      next if ($bitrate >= $threshold);
    }
    push @retain,$_;
  }

  if ($sort_by) {
    my @sorted = _sort_albums($sort_by,\@retain);
    return \@sorted;
  }
  return \@retain;
}

# Internal album sorting method (specific since I need to call methods that do not correspond to column names)
sub _sort_albums {
  my ($sort_by,$albums) = @_;
  my @sorted;
  if ($sort_by eq 'artist') {
    @sorted = sort { $a->artists cmp $b->artists } @$albums;
  } elsif ($sort_by eq 'year') {
    @sorted  = sort {$a->years <=> $b->years } @$albums;
  } elsif ($sort_by eq 'album') {
    @sorted  = sort {$a->album cmp $b->album } @$albums;
  }
  return @sorted;
}

#############################
#   ARTIST REPORTS
#############################

=pod

=head2 Artist Reports

=over 4

=item $report->artists_with_multi_genres(@options);

Generate a list of all artists with multiple genres associated to
them. Returns an array of Audio::DB::DataTypes::Artist objects, each of which
contains multiple Audio::DB::DataTypes::Genre objects. See the example
script eg/artists_with_multiple_genres for a demonstration on
accessing this data structure using provided methods.

=back

=cut

sub artists_with_multiple_genres {
  my ($self,@p) = @_;
  my $adaptor = $self->adaptor;
  my $artists = $self->fetch(-class=>'artist',-perspective=>'artists_multiple_genres');
  foreach my $artist (@$artists) {
    # Fetch the genres associated with each artist...
    my $genres = $self->fetch(-class=>'genre',-perspective=>'by_artist_id',-query=>$artist->artist_id);
    @{$artist->{genres}} = @$genres;
  }
  return $artists;
}

#############################
#   SONG REPORTS
#############################

=pod

=head1 Song Reports

The following methods provide several song-level reports.

=over 4

=item $report->song_list(@options)

Generate a list of all songs. Returns a list of
Audio::DB::DataTypes::Song objects.  This is not particularly useful
for large collections and may consume a lot of memory.

 Options:
   -sort_order    A sort key. One of artist, album, or year

The resulting list can be sorted by any of the available fields in the
song table.

=cut

sub song_list {
  my ($self,@p) = @_;
  my ($sort_by) = rearrange([qw/SORT_BY/],@p);
  my $songs = $self->fetch_class(-class=>'songs');
  if ($sort_by) {
    my @sorted = _generic_sort($sort_by,$songs);
    return \@sorted;
  }
  return $songs;
}

# I NEED SOME WAY OF DISTINGUISHING THINGS THAT SHOULD BE
# NUMERIC SORT FROM ALPHABETIC SORT
sub _genric_sort {
  my ($sort_by,$data) = @_;
  my @sorted = sort { $a->$sort_by cmp $b->$sort_by } @$data;
  return @sorted;
}


#############################
#   GENRE REPORTS
#############################
# How many songs/albums/artists of each genre?
sub genre_report {
  my ($self,@p) = @_;
  my ($sort_by,$include) = rearrange([qw/SORT_BY INCLUDE/],@p);
  my $sth;
  
  my $genres = $self->fetch(-class=>'genre',-perspective=>'all_genres');
  my @return;
  foreach my $genre (@$genres) {
    # How many songs?
    my $songs   = $self->fetch(-class=>'song',  -perspective=>'by_genre_id',-query=>$genre->genre_id);
    my $albums  = $self->fetch(-class=>'album', -perspective=>'by_genre_id',-query=>$genre->genre_id);
    my $artists = $self->fetch(-class=>'artist',-perspective=>'by_genre_id',-query=>$genre->genre_id);
    push (@{$genre->{stats}},scalar @$songs,scalar @$albums,scalar @$artists);
    if ($include) {
      @{$genre->{songs}}   = @$songs;
      @{$genre->{albums}}  = @$albums;
      @{$genre->{artists}} = @$artists;
    }
    push @return,$genre;
  }
  return wantarray ? @return : \@return;
}



#############################
#   GENERIC STATISTICS
#############################

=pod

=item $report->distribution(@options)

Create an histogram showing distribution of albums or songs by
year. Requires that the GD module be installed.

 Options:
 -class       one of albums or songs
 -width       desired width of the image in pixels
 -height      desired height of the image in pixels
 -range       array of year range to display (ie [1950..2004]).
              If not provided, all years in the collection will be used
 -background  background color for the image as an [r g b] array reference
 -foreground  foreground color for the boxes as an [r g b] array reference
 -omit_totals if provided, yearly totals will be omitted

=cut

sub distribution {
  my ($self,@p) = @_;
  my ($class,$width,$height,$range,$background,$foreground,$omit_totals)
    = rearrange([qw/CLASS WIDTH HEIGHT RANGE BACKGROUND FOREGROUND OMIT_TOTALS/],@p);

  eval { use GD; };# or die "You need to install the GD.pm module in order to use the album_distibution() method";

  # Set up some suitable defaults
  use constant DEBUG => 0;
  $width    ||= 600;
  $height   ||= 550;

  # Padding around all sides of the image
  my $PADRIGHT  = 20;
  my $PADLEFT   = 50;
  my $PADTOP    = 10;
  my $PADBOTTOM = 50;

  my $adaptor = $self->adaptor;
  my $sth = ($class eq 'songs') 
    ? $adaptor->song_queries('songs_per_year') : $adaptor->album_queries('albums_per_year');

  # Calculate the totals for each year
  my %years_seen;
  foreach (@$range) {
    $sth->execute($_);
    my ($result) = $sth->fetchrow_array;
    $years_seen{$_} = $result;
  }

  # Find the year which contains the most albums to dynamically set the y-scale
  my @sorted_years = sort { $years_seen{$a} <=> $years_seen{$b} } @$range;
  my $biggest_year = $years_seen{$sorted_years[-1]};
  my $yscale = ($height - ($PADTOP + $PADBOTTOM) - 30) / $biggest_year;

  print STDERR "y-scale: $yscale\n" if DEBUG;
  print STDERR "biggest year: $sorted_years[-1], $biggest_year\n" if DEBUG;

  my $im = new GD::Image($width,$height);

  push(@$background,255,255,0) unless @$background;
  my ($bred,$bgreen,$bblue) = @{$background};
  my $bg = $im->colorAllocate($bred,$bgreen,$bblue);

  push(@$foreground,0,255,255) unless @$foreground;
  my ($fred,$fgreen,$fblue) = @$foreground;
  my $fg    = $im->colorAllocate($fred,$fgreen,$fblue);

  my $black = $im->colorAllocate(0,0,0);
  my $blue  = $im->colorAllocate(0,0,255);
  
  $im->transparent($bg);
  $im->rectangle(0 + $PADLEFT,0 + $PADTOP,
		 $width - $PADRIGHT,$height - $PADBOTTOM,$black);

  # Set up the axis, grid, and labels
  # Create a suitable scale of y-axis tick marks
  # if drawing 10 up the axis
  my $division = int($biggest_year/10);
  my $total = $division * 10;
  for (my $i = 0;$i<=9;$i++) {
    my $y1 = ($division * $i) * $yscale + $PADBOTTOM;
    print STDERR $division . '-' . $y1,"\n" if DEBUG;
    $im->line(0+$PADLEFT-5,$y1,0 + $PADLEFT,$y1,$black);
    $im->line(0+$PADLEFT,$y1,$width - $PADRIGHT,$y1,$blue);
    $im->string(gdTinyFont,$PADLEFT-20,$y1-(gdTinyFont->height/2),($total - ($division*$i)),$black);
  }

  $im->stringUp(gdSmallFont,0+5,((($height - $PADTOP - $PADBOTTOM)/2) + (gdSmallFont->height * 1)/2),
     'TOTAL ' . uc($class),$black);
  $im->string(gdSmallFont,
	      (($width - $PADLEFT - $PADRIGHT)/2) + ((gdSmallFont->width * 5)/2),$height-20,'YEARS',$black);

  # Now I need to iterate through the range drawing boxes
  # Dynamically set the box width based on the number of years seen
  my $boxwidth = ($width - ($PADLEFT + $PADRIGHT)) / scalar (@$range);
  my $xoffset;
  foreach my $year (@$range) {
    my $total = $years_seen{$year} || 0;
    
    # normalize the yoffset to the biggest column
    my $y1 = int(($height - $PADBOTTOM) - ($total * $yscale));
    my $x1 = int($PADLEFT + $xoffset);
    
    my $x2 = int($x1 + $boxwidth);
    my $y2 = int($height - $PADBOTTOM);
    $im->filledRectangle($x1,$y1,$x2,$y2,$fg);
    $im->rectangle($x1,$y1,$x2,$y2,$black);
    #  $im->stringUp(gdTinyFont,$x1-2,$y2+25,$year,$black);
    
    # Add the year and totals
    $im->stringUp(gdTinyFont,$x1 + ((gdTinyFont->width * 1)/2),$y2+25,$year,$black);
    unless ($omit_totals) {
      $im->stringUp(gdTinyFont,$x1 + ((gdTinyFont->width * 1)/2),$y1-5,$total,$black);
    }
    $xoffset += $boxwidth;
    print STDERR join("\t",$year,$total,$x1,$y1,$x2,$y2),"\n" if DEBUG
  }

  my $string = $im->png;
  return $string;
}


=pod

=item $report->library_size()

Calculate the full size of your library. Returns a hash reference
containing the size in kilobytes (Kb), megabytes (MB), and the size in
gigabytes (GB).

=cut

sub library_size {
  my $self = shift;
  my $adaptor = $self->adaptor;
  my $size = $adaptor->query_for_total('filesize');
  my %stats;
  $stats{MB} = sprintf ('%.3f',($size / (1024 * 1024)));
  $stats{GB} = sprintf ('%.3f',($size / (1024 * 1024 * 1024)));
  $stats{Kb} = $size;
  return \%stats;
}

=pod

=item $report->library_duration()

Calculate the full duration of your library. Returns a hash reference
containing the breakdown of the total duration using the hash keys
days, minutes, hours, and seconds.  For convenience, the total time is
also returned as a formatted string of DD::HH::MM::SS under the hash
key "total_time".

=cut

sub library_duration {
  my $self = shift;
  my $adaptor = $self->adaptor;
  my $milliseconds = $adaptor->query_for_total('seconds');
  my $seconds = int($milliseconds / 1000);
  my $days  = _save_remainder($seconds,60 * 60 * 24);
  my $hours = _save_remainder($seconds,60 * 60);
  my $min   = _save_remainder($seconds,60);
   my %stats;
  $stats{days}       = $days;
  $stats{minutes}    = $min;
  $stats{hours}      = $hours;
  $stats{seconds}    = int $seconds;
  $stats{total_time} = join(':',$days,$hours,$min,$seconds);
  return \%stats;
}

sub _save_remainder {
  my ($val) = int($_[0] / $_[1]);
  $_[0] -= $val * $_[1];
  return $val;
}


=pod

=item $report->counts()

Generate simple counts of the primary classes in the library. Returns
a hash reference with the following keys: songs, artists, albums, and
genres.

=cut

sub counts {
  my $self = shift;
  my %stats;
  $stats{songs}   = $self->count('songs');
  $stats{artists} = $self->count('artists');
  $stats{albums}  = $self->count('albums');
  $stats{genres}  = $self->count('genres');
  return \%stats;
}



1;

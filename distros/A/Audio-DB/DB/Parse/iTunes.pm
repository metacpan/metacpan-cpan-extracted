package Audio::DB::Parse::iTunes;
use strict;
use vars qw/@ISA/;

#@ISA = qw/Audio::DB::Build/;
@ISA;

# Subroutines for parsing iTunes XML-ified libraries

sub parse_library {
  my ($name,$self,$library) = @_;
  -e $library or die "$library does not exist: $!\n";
  open (XML,"<$library") or die "$library could not be opened: $!.";
  $/ = "<dict>";
  while (<XML>) {
    if (/Artist/i || /Album/i) {
      my @lines = split("\n");
      my %data;
      foreach (@lines) {
	my ($key) = $_ =~ m|<key>(.*)</key>|;
	my $value;
	if ($key eq 'Compilation') {
	  $value = 'true';
	} else {
	  ($value) = $_ =~ /<key>.*<\/key><.*>(.*)<\/.*>/;
	}
	$data{$key} = $value;
      }
      next if $data{Artist} eq "Griffin Technology"; # itrip and other peripherals.
      
      my $ph = '\N';
      my $tag = {};
      # Mimic handling of the get_tags data structure
      $tag = {
	      title        => $data{Name}           || $ph,
	      artist       => $data{Artist}         || $ph,
	      duration     => $data{Time}           || $ph,
	      genre        => $data{Genre}          || $ph,
	      album        => $data{Album}          || $ph,
	      comment      => $data{Comment}        || $ph,
	      year         => $data{Year}           || $ph,
	      min          => $data{'Total Time'}   || $ph,
	      sec          => $data{'Total Time'}   || $ph,
	      seconds      => $data{'Total Time'}   || $ph,
	      lyrics       => $data{Lyrics}         || $ph,
	      track        => $data{'Track Number'} || $ph,
	      total_tracks => $data{'Track Count'}  || $ph,
	      bitrate      => $data{'Bit Rate'}     || $ph,
	      samplerate   => $data{'Sample Rate'}  || $ph,
	      composer     => $data{Composer}       || $ph,
	      discnumber   => $data{'Disc Number'}  || $ph,
	      disccount    => $data{'Disc Count'}   || $ph,
	      dateadded    => $data{'Date Added'}   || $ph,
	      datemodified => $data{'Date Modified'}|| $ph,
	      compilation  => $data{Compilation}    || $ph,
	      filename     => $data{Location}       || $ph,
	      filepath     => $data{Location}       || $ph,
	      filesize     => $data{Size}           || $ph,
	      tagtypes     => $ph,
	      fileformat   => $data{Kind}           || $ph,
	      channels     => $ph,
	      vbr          => $ph,
	      rating       => $data{Rating}         || $ph,
	      playcount    => $data{'Play Count'}   || $ph,
	      playdate     => $data{'Play Date'}    || $ph,
	     };
      $self->cache_song($tag);
    }
  }
}




######### PURGING

sub aggregate_stats {
  my ($self,$type,$hashref,$library,$album) = @_;
  warn "$type -" . join('-',keys %$hashref) . scalar (keys %$hashref);
  if ((scalar keys %$hashref > 1) && $type ne 'track') {
    $self->{libraries}->{$library}->{albums}->{$album}->{$type} = "multiple $type" . 's assigned';
  } else {
    my @temp = map {$_} keys %$hashref;
    $self->{libraries}->{$library}->{albums}->{$album}->{$type} = $temp[0];
  }
}
##############

# Filter albums based on user-supplied params This type of approach
# lends itself well to finding artists with multiple genres
sub filter_albums {
  my ($self,$lib,$requested_formats,$bitrate_minimum,$uniques) = @_;
  my @rows;
  
  $self->aggregate_songs_into_albums($lib,$uniques);
  my @albums = $self->albums($lib);
  foreach my $album_key (@albums) {
    my $artist  = $self->{libraries}->{$lib}->{albums}->{$album_key}->{artist};
    my $bitrate = $self->{libraries}->{$lib}->{albums}->{$album_key}->{bitrate};
    my $album   = $self->{libraries}->{$lib}->{albums}->{$album_key}->{album};
    my $genre   = $self->{libraries}->{$lib}->{albums}->{$album_key}->{genre};
    my $year    = $self->{libraries}->{$lib}->{albums}->{$album_key}->{year};
    my $kind    = $self->{libraries}->{$lib}->{albums}->{$album_key}->{kind};
    my $tracks  = $self->{libraries}->{$lib}->{albums}->{$album_key}->{track};

    $artist = ($artist =~ /multiple\sartist/i) ? 'Various Artists' : $artist;

    next unless (defined $requested_formats->{$kind});               # Ignore unless user has requested this format
    next if ($bitrate < $bitrate_minimum || $bitrate =~ /multiple/); # Ignore if we are below the bitrate minimum
    # Only save it if the total songs seen matches the track count
    next unless ($tracks == scalar @{$self->{libraries}->{$lib}->{albums}->{$album_key}->{songs}});
    # Do we pass all the appropriate criteria?  Create a row in the table
    push @rows,[$artist,$album,$tracks,$bitrate,$kind,$year,$genre];
  }
  return @rows;
}



# If called with an opposite_library name, we are through comparing
# libraries and are simply calculating what is left.
sub summarize_by_song {
  my ($self,$library,$status,$opposite_library) = @_;
  $library ||= $self->get_name();
  $status  ||= 'total';
  my (%unique_artists,%unique_albums);
  foreach my $song_key ($self->songs($library)) {
    my $song = $self->song($library,$song_key);

    # Full collection aggregates
    $self->{libraries}->{$library}->{stats}->{$status . '_songs'}++;
    $self->{libraries}->{$library}->{stats}->{$status . '_size'}  += $song->{Size};
    $self->{libraries}->{$library}->{stats}->{$status . '_time'}  += $song->{'Total Time'};
    my $album  = lc($song->{Album});
    my $artist = lc($song->{Artist});
    if ($opposite_library) {
      $unique_artists{$artist}++ if (!defined $self->{libraries}->{$opposite_library}->{all_artists}->{$artist});
      $unique_albums{$album}++   if (!defined $self->{libraries}->{$opposite_library}->{all_albums}->{$album});
    } else {
      $unique_artists{$artist}++;
      $unique_albums{$album}++;
    }
  }
  
  #  my @songs = $self->songs($);
  #  warn $name . ' ' . (scalar @songs) . ' ' . (scalar keys %unique_artists);
  #  warn $name . ' ' . (scalar keys %unique_albums);
  # Add some various full collection totals
  $self->{libraries}->{$library}->{stats}->{$status . '_albums'}  = keys %unique_albums;
  $self->{libraries}->{$library}->{stats}->{$status . '_artists'} = keys %unique_artists;
}



# If parsing by songs, we might want to aggregate into albums
# Can optionally pass a list of songs (ie unique songs) instead
# of processing the entire list
sub aggregate_songs_into_albums {
  my ($self,$library,$songs) = @_;
  $library ||= $self->get_name();
  if ($songs) {
    foreach my $song (@$songs) {
      my $album_key = $self->create_album_key($song);
      push(@{$self->{libraries}->{$library}->{albums}->{$album_key}->{songs}},$song);
      # delete $self->{songs}->{$song_key}; # To save on some memory
    }
  } else {
    $songs = $self->songs($library);
    foreach my $song_key (@$songs) {
      my $song = $self->song($library,$song_key);
      my $album_key = $self->create_album_key($song);
      push(@{$self->{libraries}->{$library}->{albums}->{$album_key}->{songs}},$song);
      # delete $self->{songs}->{$song_key}; # To save on some memory
    }
  }

  # Create some aggregate, per album stats
  foreach my $album ($self->albums($library)) {
    my (%bitrates,%genres,%years,%artists,%albums,%kinds,%tracks);
    foreach my $song (@{$self->{libraries}->{$library}->{albums}->{$album}->{songs}}) {
      # Per album aggregates
      # Track total number of times songs on this album have been played
      $self->{libraries}->{$library}->{albums}->{$album}->{total_play_count} += $song->{'Play Count'} if (defined $song->{'Play Count'});
      $self->{libraries}->{$library}->{albums}->{$album}->{total_size} += $song->{'Size'} if (defined $song->{Size});
      $self->{libraries}->{$library}->{albums}->{$album}->{total_time} += $song->{'Total Time'} if (defined $song->{'Total Time'});
      
      # Aggregate bitrates, genres, years
      $bitrates{$song->{'Bit Rate'}}++;
      $genres{$song->{Genre}}++;
      $years{$song->{Year}}++;
      $artists{$song->{Artist}}++;
      $albums{$song->{Album}}++;
      $kinds{$song->{Kind}}++;
      $tracks{$song->{'Track Count'}}++;
    }
    $self->aggregate_stats('bitrate',\%bitrates,$library,$album);
    $self->aggregate_stats('genre',\%genres,$library,$album);
    $self->aggregate_stats('year',\%years,$library,$album);
    $self->aggregate_stats('artist',\%artists,$library,$album);
    $self->aggregate_stats('album',\%albums,$library,$album);
    $self->aggregate_stats('kind',\%kinds,$library,$album);
    $self->aggregate_stats('track',\%tracks,$library,$album);
  }
}

# Try to create a unique key for the album
sub create_album_key {
  my ($self,$song) = @_;
  my $album  = $song->{Album};
  my $artist = eval {$song->{Compilation} } ? 'various_artists' : $song->{Artist};
  my $key = $album . '-' . $artist;
  return $key;
}

# Create a song key that is highly likely to be unique.  This will be
# track number - name - album We are not using artist becasue of
# possible differences in naming schemes (First Last versus Last,
# First) Even if an album has two songs of the same name, they will
# rarely be the same track

# This approach means that I will lose some songs by default in the analysis
sub create_song_key {
  my ($self,$song) = @_;
  my $album  = lc($song->{Album});
  my $title  = lc($song->{Name});
  #  my $artist = lc($song->{Artist});
  my $track  = eval { $song->{'Track Number'} } || '0';
  my $key = join('',$track,$title,$album);
  #  $key =~ s/[\s\t\(\)\.\,\\\/\*\?\.\!\-]//g;  # Get rid of as many weird characters as possible.
  $key =~ s/[\r\n\t\s\[\]\(\)\-\=\,\.\"\'\\\/\+\$\*\!\?]//g;
  return $key;
}

sub artist_genres {
  my ($self,$library_name) = @_;
  return $self->{libraries}->{$library_name}->{artist_genres};
}

# Accessors
sub albums {
  my ($self,$library) = @_;
  my @albums = keys %{$self->{libraries}->{$library}->{albums}};
  return @albums;
}

# deprecated / not converted
# Return the songs of the album sorted by their track number
#sub songs_from_album {
#  my ($self,$album) = @_;
#  my @songs = sort {eval { $a->{'Track Number'}} <=> eval {$b->{'Track Number'}} } 
#    @{$self->{albums}->{$album}->{songs}};
#  return @songs;
#}

# Retrieve possible duplicates from this single library
sub single_library_duplicates {
  my ($self,$library) = @_;
  my @dups = @{$self->{libraries}->{$library}->{duplicates}};
  return @dups;
}


sub songs {
  my ($self,$library) = @_;
  $library ||= $self->get_name();
  my @songs = keys %{$self->{libraries}->{$library}->{songs}};
  return @songs;
}

sub song {
  my ($self,$library,$songkey) = @_;
  $library ||= $self->get_name();
  return $self->{libraries}->{$library}->{songs}->{$songkey};
}

# use the all albums entry to get the total track count for the given album
# (I use this as a measure of whether a song is a single or not)
sub album_track_count {
  my ($self,$library,$album) = @_;
  return ($self->{libraries}->{$library}->{all_albums}->{$album});
}


=pod

=head1 Audio::DB::Parse::iTunes.pm

Glean information on music files from an iTunes XML library file.

=head1 DESCRIPTION

Audio::DB::Parse::iTunes.pm is used internally by Audio::DB. It's
internal, private methods will be called when trying to create or update
a music database using the 'itunes' option:

      $mp3->load_database(-dirs =>['/path/to/iTunes Music Library.xml/'],
		          -verbose  => 100);

All methods of Audio::DB::Parse::iTunes are private (for now). You
will never need to interact with Audio::DB::Parse::iTunes objects
directly.

=head1 REQUIRES
    
=head1 EXPORTS

No methods are exported.

=head1 METHODS

No public methods available.

=head1 PRIVATE METHODS

TO BE COMPLETED SOON, I PROMISE!

=head1 AUTHOR

Copyright 2002-2004, Todd W. Harris <harris@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=head1 SEE ALSO

L<Audio::DB>

=cut



1;

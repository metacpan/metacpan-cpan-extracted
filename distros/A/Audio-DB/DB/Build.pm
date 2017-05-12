package Audio::DB::Build;

# $Id: Build.pm,v 1.2 2005/02/27 16:56:25 todd Exp $
use strict 'vars';

use Carp 'croak','cluck';
use vars qw(@ISA $VERSION);

use Audio::DB;
use Audio::DB::Parse::iTunes;
use Audio::DB::Parse::FlatFile;
use Audio::DB::Parse::ReadFiles;
use Audio::DB::Util::Rearrange;

my $ENV_TMP = $ENV{TMP} || $ENV{TMP_DIR} || (-d '/tmp') ? '/tmp' : (-d '/var/tmp') ? '/var/tmp' : '';

$|++;

@ISA = qw/Audio::DB Audio::DB::Util::DataAccess/;

$VERSION = '';

# Initialize a new database
sub initialize {
  my $self = shift;
  my $adaptor = $self->adaptor;
  if (defined $self->{shout}) { print STDERR "Initializing database...\n"; };
  $adaptor->do_initialize(1) if @_ == 1 && $_[0];
  my ($erase,$meta) = rearrange(['ERASE'],@_);
  $meta ||= {};
  
  # initialize (possibly erasing)
  return unless $adaptor->do_initialize($erase);
  # return;
  1;
}


# Wrapper method for quickly building a database
# I think that much of this code belongs in the adaptor...
sub load_database {
  my ($self,@p) = @_;
  my ($dirs,$files,$library,$columns,$tmp,$shout,@others) =
    rearrange([
	       [qw(DIR DIRS TOP_DIRS)],
	       FILES,
	       LIBRARY,	
	       COLUMNS,
	       TMP,
	       [qw(VERBOSE YELL SCREAM)],
	      ],@p);
  
  # Set some system-level variables
  $tmp ||= $ENV_TMP;
  $self->{tmp}   = $tmp;
  $self->{shout} = $shout if ($shout);

  # User has supplied an iTunes library file. Let's parse that.
  if ($library) {
    Audio::DB::Parse::iTunes->parse_library($self,$library);
  } elsif (@$files > 0) {
    # Parsing information from a flat file of mp3 information
    Audio::DB::Parse::FlatFile->parse_files($self,$files,$columns);
  } else {
    # Reading data directly from MP3z...
    Audio::DB::Parse::ReadFiles->process_directories($self,$dirs);
  }

  my $adaptor = $self->adaptor;
  $self->_dump_data_structures();
  $self->_load_db();
  my $stats = $self->get_stats();
  return $stats;
}


# UPDATE DATABASE IS NOT COMPLETELY WORKING YET!!
# Wrapper method for quickly adding new songs to a database.
# This needs to check within the DB itself for artists
# and albums, as well as within the current set.
sub update_database {
  my ($self,@p) = @_;
  my ($dirs,$files,$columns,$tmp,$shout,@others) =
    rearrange([
	       [qw(DIR DIRS TOP_DIRS)],
	       FILES,
	       COLUMNS,
	       TMP,
	       [qw(VERBOSE YELL SCREAM)],
	      ],@p);
  
  # Establish the counters based on preexisitng values in database
  $self->_establish_counters();

  if ($files) {
    Audio::DB::Parse::FlatFile->parse_files($self,$files,$columns);
  } else {
    # Reading data directly from MP3z...
    # Save the top level directory
    
    @{$self->{top_dirs}} = @{$dirs};
    $tmp ||= $ENV_TMP;
    $self->{tmp}   = $tmp;
    $self->{shout} = $shout if ($shout);
    Audio::DB::Parse::ReadFiles->process_directories($self);
  }

  $self->_dump_data_structures();
  $self->_load_db();
  return;
}

sub get_stats {
  my $self = shift;
  my $stats = {};
  $stats->{artists} = $self->{counters}->{artists};
  $stats->{albums}  = $self->{counters}->{albums};
  $stats->{genres}  = $self->{counters}->{genres};
  $stats->{songs}   = $self->{counters}->{songs};
  return $stats;
}


# TODO WARNING
# This is ONLY used during updates and has not been brought up-to-date.
# Get the highest values for each before adding
# new info to the DB.
# This requires MySQL specific code and should probably be moved...
# not documented yet
sub _establish_counters {
  my $self = shift;
  if (defined $self->{shout}) { print STDERR "Establishing counters...\n"; };
  my $adaptor = $self->adaptor;
  my $dbh = $adaptor->dbh();
  my %fields = (
		song_id   => songs,
		artist_id => artists,
		album_id  => albums,
		genre_id  => genres);
  
  foreach (keys %fields) {
    my $sth = $adaptor->lookup_counter($_,$fields{$_});
    $sth->execute();
    my ($id) = $sth->fetchrow_array;
    $self->{counters}->{$fields{$_}} = $id;
  }
  return;
}

# Caveats -
# Singles are either labelled as "singles" or with nothing
# Albums of the same name can only be distiniguished if their year and total_tracks
# are differnet.  If you haven't assigned either of these, you'll have one less
# metric for distinguishing albums.

# I SHOULD KEEP FULL COLLECTION STATISTICS HERE TOO (
# THIS WOULD REQUIRE A NEW TABLE

sub cache_song {
  my ($self,$song) = @_;
  return if (!$song);
  my $artist = $song->{artist};
  my $album  = $song->{album};
  
  # Check to see if we have seen this artist, genre, or album before
  my $artist_id = $self->_check_artist_mem($artist);
  my $genre_id  = $self->_check_genre_mem($song->{genre});
  my $album_id  = $self->_check_album_mem($song,$artist_id);
  
  my $id = ++$self->{counters}->{songs};
  
  if (defined $self->{shout} && ($id % $self->{shout}) == 0) {print_msg("Songs processed : $id") };

  # Would be nice to generate the song_types join, flagging possible live tracks, covers, etc...
  $self->{songs}->{$id} = {
			   title        => $song->{title},
			   artist_id    => $artist_id,
			   album_id     => $album_id,
			   genre_id     => $genre_id,
			   track        => $song->{track},
			   total_tracks => $song->{total_tracks},
			   duration     => $song->{duration},
			   seconds      => $song->{seconds},
			   bitrate      => $song->{bitrate},
			   samplerate   => $song->{samplerate},
			   comment      => $song->{comment},
			   filename     => $song->{filename},
			   filesize     => $song->{filesize},
			   filepath     => $song->{filepath},
			   tagtypes     => $song->{tagtypes},
			   format       => $song->{layer},
			   channels     => $song->{channels},
			   year         => $song->{year},   # normally this is stored with album
			   rating       => $song->{rating}, # but could be different for comps
			   playcount    => $song->{playcount}
			  };
  
  # Store some additional information about each album in order
  # to create artist_album and artist_genre associations
  # This way I can easily find albums that have more than a single
  # genre assigned to them 
  $self->{artists}->{$artist_id}->{albums}->{$song->{album}} = $album_id;
  $self->{artists}->{$artist_id}->{genres}->{$genre_id}++;
  # Finally, add some additional information to the albums hash
  
  # This is an easy way of keeping track of compilation CDs -
  # autoincrement each time I see an artist. Compilations will have multiple keys
  # I can then flag this album as a compilation if I so desire when dumping the table
  $self->{albums}->{$album_id}->{contributing_artists}->{$artist_id}++;
  return;
}

sub _stuff_album {
  my ($self,$tag) = @_;
  my $album_id = ++$self->{counters}->{albums};
  my $track        = $tag->{track};
  my $tot_tracks   = $tag->{total_tracks};
  $self->{albums}->{$album_id} = { album        => $tag->{album},
				   total_tracks => $tot_tracks,
				   year         => $tag->{year},
				 };
  # Store the album in the lookups hash
  $self->{lookups}->{albums}->{$tag->{album}} = $album_id;
  return $album_id;
}


###############################
# Internal methods that check #
# if we have seen artist,     #
# album, or genre yet         #
###############################
sub _check_artist_mem {
  my ($self,$artist) = @_;
  if (defined $self->{lookups}->{artists}->{$artist}) {
    # There is an artist stored, but perhaps it's a duplicate name?
    # Need to deal with this somehow...
    # TO DO: Need to handle artists that have the same name...
   return $self->{lookups}->{artists}->{$artist};
  } else {
    # This is our first encounter
    # increment the id and return it
    # Store the artist in the lookup hash and
    # initialize in the artist hash
    my $id = ++$self->{counters}->{artists};
    $self->{lookups}->{artists}->{$artist} = $id;
    $self->{artists}->{$id} = { artist => $artist };
    return $id;
  }
}

sub _check_genre_mem {
  my ($self,$genre) = @_;
  # Genres are unique - they are simple to deal with
  if (defined $self->{lookups}->{genres}->{$genre}) {
    return $self->{lookups}->{genres}->{$genre};
  } else {
    # If not, enter this genre into the 
    # lookups hash and the corresponding genre hash
    my $id = ++$self->{counters}->{genres};
    $self->{lookups}->{genres}->{$genre} = $id;
    $self->{genres}->{$id} = $genre;
    return $id;
  }
}

sub _check_album_mem {
  my ($self,$tag,$artist_id) = @_;
  my $artist       = $tag->{artist};
  my $album        = $tag->{album};
  my $year         = $tag->{year};
  my $track        = $tag->{track};
  my $tot_tracks   = $tag->{total_tracks};

  my $album_id;
  if (defined $self->{lookups}->{albums}->{$album}) {
    my $test_id = $self->{lookups}->{albums}->{$album};
    # 1. Perhaps this is just a "single", not part of an album.
    # Generally this may be an mp3 that is lacking an album tag
    # At any rate, I want each song that is either labelled as a single
    # or is blank to be listed as part of its own album, and not grouped together
    
    # This should probably be fixed.
    if ($album =~ /^singles/i) {
      # Check to see if I've added the singles album to this artist...
      if (defined $self->{artists}->{$artist_id}->{albums}->{$album}) {
	$album_id = $self->{artists}->{$artist_id}->{albums}->{$album};
      } else {
	# A new album - lets enter it into the object
	$album_id = $self->_stuff_album($tag);
      }
    }
    
    # 2. Maybe we have just hit two albums with the same name
    # See if the year and total tracks are the same.
    # Would be nice to have some other metric of grouping...
    # File paths, genres, etc...
    if (!$album_id) {
      # USING THE YEAR WILL NOT WORK!
      # Many albums have songs where the years are different!
      #      my $stored_year   = $self->{albums}->{$test_id}->{year};
      my $stored_tracks = $self->{albums}->{$test_id}->{total_tracks};
      #      if ($stored_year != $year || $stored_tracks != $tot_tracks) {
      if ($stored_tracks != $tot_tracks) {
	# Aah!  A conflict - let's enter a new album!
	$album_id = $self->_stuff_album($tag);
      }
    }
    
    # If neither of those metrics revealed a discrepancy with the
    # identified album, then it might just possibly be another track from
    # a preexisting album.
    # Set album_id to the temp_id
    $album_id ||= $test_id;
  } else {
    $album_id = $self->_stuff_album($tag);
  }
  return $album_id;
}



################################################
# Temp table generating subs
################################################
# Need to make song_genres and song_types;
sub _dump_data_structures {
  my $self = shift;
  if (defined $self->{shout}) { print STDERR "\nDumping tables...\n"; };
  $self->_dump_artists();
  $self->_dump_albums();
  $self->_dump_genres();
  $self->_dump_songs();
  return;
}


# TODO WARNING
# Figure out how to purge this adaptor specific code
# I REALLY hate that there is adaptor specific code here
# Generate the artists and artist_genres table
sub _dump_artists {
  my $self = shift;
  my $adaptor = $self->adaptor;
  my $dbh = $adaptor->dbh;
  open OUT, ">$self->{tmp}/artists" or die "Couldn't open temporary file: $!";
  open OUT2,">$self->{tmp}/artist_genres" or die "Couldn't open temporary file: $!";
  foreach my $artist_id (sort keys %{$self->{artists}}) {
    my $artist = $self->{artists}->{$artist_id}->{artist};
    if ($adaptor =~ /sqlite/) {
      $dbh->do("INSERT INTO artists (artist_id,artist) VALUES (?,?)",undef,($artist_id,$artist));
    } else {
      print OUT join("\t",$artist_id,$artist),"\n";
    }
    # artist_genre join table
    foreach my $genre_id (keys %{$self->{artists}->{$artist_id}->{genres}}) {
      if ($adaptor =~ /sqlite/) {
	$dbh->do("INSERT INTO artist_genres (artist_id,genre_id) VALUES (?,?)",undef,($artist_id,$genre_id));
      } else {
	print OUT2 join("\t",$artist_id,$genre_id),"\n";
      }
    }
  }
  close OUT;
  close OUT2;
}

# Generate the album and album_artists join tables
sub _dump_albums {
  my $self = shift;
  # Need to open two file handles...
  # Albums and Album artists
  open OUT, ">$self->{tmp}/albums" or die "Couldn't open temporary file: $!";
  open OUT2,">$self->{tmp}/album_artists" or die "Couldn't open temporary file: $!";
  my $adaptor = $self->adaptor;
  my $dbh = $adaptor->dbh;
  foreach my $album_id (sort keys %{$self->{albums}}) {
    my $album      = $self->{albums}->{$album_id}->{album};  
    my $year       = $self->{albums}->{$album_id}->{year};
    my $tot_tracks = $self->{albums}->{$album_id}->{total_tracks};
    my $type = (scalar keys %{$self->{albums}->{$album_id}->{contributing_artists}} == 1) ? 'standard' : 'compilation';
 
    # Album table 
    if ($adaptor =~ /sqlite/) {
      $dbh->do("INSERT INTO albums (album_id,album,type,total_tracks,year) VALUES (?,?,?,?,?)",undef,
	       ($album_id,$album,$type,$tot_tracks,$year));
    } else {
      print OUT join("\t",$album_id,$album,$type,$tot_tracks,$year),"\n";
    }
    # album_artists join table
    foreach my $artist_id (keys %{$self->{albums}->{$album_id}->{contributing_artists}}) {
      if ($dbh =~ /sqlite/) {
	$dbh->do("INSERT INTO album_artists (artist_id,album,type) VALUES (?,?,?)",undef,
		 ($artist_id,$album,$type));
      } else {
	print OUT2 join("\t",$artist_id,$album_id),"\n";
      }
    }
  }
  close OUT;
  close OUT2;
}

# Generate the genre table
sub _dump_genres {
  my $self = shift;
  my $adaptor = $self->adaptor;
  my $dbh = $adaptor->dbh;
  open OUT,">$self->{tmp}/genres" or die "Couldn't open temporary file: $!";
  foreach my $genre_id (sort keys %{$self->{genres}}) {
    my $genre = $self->{genres}->{$genre_id};
    if ($adaptor =~ /sqlite/) {
      $dbh->do("INSERT INTO genres (genre_id,genre) VALUES (?,?)",undef,($genre_id,$genre));
    } else {
      print OUT join("\t",$genre_id,$genre),"\n";
    }
  }
  close OUT;
}

# Generate the songs table
sub _dump_songs {
  my $self = shift;
  my $adaptor = $self->adaptor;
  my $dbh = $adaptor->dbh;
  open OUT,">$self->{tmp}/songs" or die "Couldn't open temporary file: $!";
    foreach my $song_id (sort keys %{$self->{songs}}) {
    my $href = $self->{songs}->{$song_id};
    if ($adaptor =~ /sqlite/) {
      $dbh->do("INSERT INTO songs (song_id,title,artist_id,album_id,genre_id,track,duration,seconds,lyrics,comment,bitrate,samplerate,fileformat,channels,tagtypes,filename,filesize,filepath,year,rating,playcount,dateadded,datemodified) VALUES (?,?,?,?,?,?
,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",undef,
	       ($song_id,
		$href->{title},
		$href->{artist_id},
		$href->{album_id},
		$href->{genre_id},
		$href->{track},
		$href->{duration},
		$href->{seconds},
		$href->{lyrics},
		$href->{comment},
		$href->{bitrate},
		$href->{samplerate},
		$href->{format},
		$href->{channels},
		$href->{tagtypes},
		$href->{filename},
		$href->{filesize},
		$href->{filepath},
		$href->{year},
		$href->{rating},
		$href->{playcount},
		$href->{dateadded} || '\N',
		$href->{datemodified} || '\N',));
    } else {
      print OUT join("\t",$song_id,
		     $href->{title},
		     $href->{artist_id},
		     $href->{album_id},
		     $href->{genre_id},
		     $href->{track},
		     $href->{duration},
		     $href->{seconds},
		     $href->{lyrics},
		     $href->{comment},
		     $href->{bitrate},
		     $href->{samplerate},
		     $href->{format},
		     $href->{channels},
		     $href->{tagtypes},
		     $href->{filename},
		     $href->{filesize},
		     $href->{filepath},
		     $href->{year},     # Denormalization to account for compilation CDs
		     $href->{rating},
		     $href->{playcount}
		    ),"\n";
    }
  }
  close OUT;
}

# TODO WARNING
# Figure out how to purge this adaptor specific code
sub _load_db {
  my $self = shift;

  if (defined $self->{shout}) { print STDERR "Loading tables...\n" };
  # Fetch the table names
  my $adaptor = $self->adaptor;
  my @tables = $adaptor->tables;
  my $dbh = $adaptor->dbh;
  my $tmp = $self->{tmp};
  foreach (@tables) {
    if (-e "$tmp/$_") {
      if ($adaptor =~ /sqlite/) {
	# SQLite does not support infile loads, apparently. Bummer.
      } elsif ($adaptor =~ /mysql/) {
	# $dbh->do("lock tables $_ write; delete from $_; load data infile '$tmp/$_' replace into table $_; unlock tables");
	if (defined $self->{shout}) { print STDERR "loading table $_...\n"; }
	$dbh->do("load data infile '$tmp/$_' replace into table $_") or warn "COULDN'T LOAD TABLE $_";
      } else {};
    }
    unlink "$self->{tmp}/$_";
  }
}


sub get_couldnt_read {
  my $self = shift;
  my @couldnt = @{$self->{couldnt_read}};
  return \@couldnt;
}


sub print_msg {
  my $msg = shift;
  print STDERR $msg;
  print STDERR -t STDOUT && !$ENV{EMACS} ? "\r" : "\n";
}

1;

=pod

=head1 NAME
    
Audio::DB - Tools for generating relational databases of MP3s
    
=head1 SYNOPSIS

      use Audio::DB;
      my $mp3 = Audio::DB->new(-user    =>'user',
			       -pass    =>'password',
			       -host    =>'db_host',
			       -dsn     =>'music_db',
                               -adaptor => 'mysql');

      $mp3->initialize(1);

      $mp3->load_database(-dirs =>['/path/to/MP3s/'],
		          -tmp  =>'/tmp');

=head1 DESCRIPTION

Audio::DB is a module for creating relational databases of MP3 files
directly from data stored in ID3 tags or from flatfiles of information
of track information.  Once created, Audio::DB provides various methods
for creating reports and web pages of your collection. Although it's
nutritious and delicious on its own, Audio::DB was created for use with
Apache::Audio::DB, a subclass of Apache::MP3.  This module makes it easy
to make your collection web-accessible, complete with browsing,
searching, streaming, multiple users, playlists, ratings, and more!

=head1 REQUIRES
    
B<MP3::Info> for reading ID3 tags, B<LWP::MediaTypes> for distinguising 
types of readable files;

=head1 EXPORTS
    
No methods are exported.
    
=head1 CAVEATS

Metrics for assigning songs to albums:
Since Audio::DB processes file-by-file, it uses a number of parameters to assign
tracks to albums.  The quality of the results of Audio::DB will depend directly 
on the quality and integrity of the ID3 tags of your files.

Single tracks (those not belonging to a specific album) are distinguished by 
either undef or the label "single" in the album tag.  In this way, all the single tracks
for a given artist can be easily grouped together and fetched as a sort of 
pseudo-album. Of course, since you've ripped all of your MP3z from albums that you own,
this shouldn't be a problem ;).

If two or more albums have the same name ("Greatest Hits"), Audio::DB checks 
to see if the year they were released and the total number of tracks is the same.  
If so, it thinks they are the same album, and all tracks are grouped together.  
This works most of the time, but obviously will fail sometimes. If you haven't
assigned either of these tags, you'll have one less metric for distinguishing 
tracks.  If you have a better metric for distinguishing tracks, please let me know!

=head1 METHODS

=head2 initialize

 Title   : initialize
 Usage   : $mp3->initialize(-erase=>$erase);
 Function: initialize a new database
 Returns : true if initialization successful
 Args    : a set of named parameters
 Status  : Public

This method can be used to initialize an empty database.  It takes the following
named arguments:

  -erase     A boolean value.  If true the database will be wiped clean if it
             already contains data.

A single true argument ($mp3->initialize(1) is the same as initialize(-erase=>1).
Future versions may support additional options for initialization and database
construction (ie custom schemas).

=head2 load_database

 Title   : load_database
 Usage   :

       Creating a database by reading the tags from MP3 files:
       $stats = $mp3->load_database(-dirs    => ['/path/to/MP3s/'],
                	            -tmp     => '/tmp',
                                    -verbose => 100);

       Creating a database from a flat file of file information
:       $stats = $mp3->load_database(-files   => ['/path/to/files/'],
                                    -columns  => '[columns in file]',
	                            -tmp      => '/tmp',
                                    -verbose  => 100);

       Creating a database from the iTunes Music Library.xml file
       $stats = $mp3->load_database(-library  => '/path/to/iTunes\ Music\ Library.xml',
                                    -verbose  =>  100);

 Function: Parses mp3s and loads database
 Returns : Hash reference containing number of artists, albums, songs,
           and genres processed.
 Args    : array of top-level paths to mp3s; path to tmp directory, 
           verbose flag
 Status  : Public

load_database is a broad wrapper method that provides simplified
access to many Audio::DB less-public methods.  load_database expects an
array of top level paths to directories containing MP3s to load.  The
second required parameter is the path to a suitable /tmp directory.
Audio::DB::Build will write temporary files to this directory prior to doing
bulk loads into the database.

The optional -verbose flag will a variety of messages to be displayed
to STDERR during processing. The value of -verbose controls how
frequently to display a message during song processing.

Instead of reading the tags directly, a flat file or files containing
the ID3 tag information can be read.  This is particularly useful, in
part for offline files that have been cataloged with utilities like
MP3Rage.  Furthermore, I've found that the MP3::Info modules that
Audio::DB::Build relies on isn't as robust at reading tags as other
applications.  The path to individual files or directories contain
batches of these files should be passed in as an anonymous array.  A
second parameter, columns, should also be passed showing the order of
the fields in the file.  Minimally, the file should contain album,
artist, and title.  The following column names should be adhered to:

       title        => song title
       artist       => performing artist
       album        => containing album
       track        => song track number
       total_tracks => total tracks on album
       duration     => [optional] formatted string of song duration
       seconds      => [optional] song duration in seconds
       bitrate      => [optional] integer. The bitrate of the song
       samplerate   => [optional] sample rate of encoding
       comment      => [optional] song comment
       filename     => [optional] duh.
       filesize     => [optional] file size in kb
       filepath     => [optional] absolute file path
       tagtypes     => [optional] ID3 tag types present
       fileformat   => [optional] file format
       channels     => [optional] number of channels
       year         => [optional] year of the album
       rating       => [optional] user rating
       playcount    => [optional] song play count
       playdate     => [optional] date song last played
       dateadded    => [optional] date song added to collection
       datemodified => [optional] date song information last modified

=head2 update_database

 Title   : update_database
 Usage   : $mp3->update_database(-dirs    =>['/path/to/MP3s/'],
 		                 -tmp     =>'/tmp',
                                 -verbose => '/100/');

           $mp3->update_database(-files    =>['/path/to/files'],
		                 -columns  =>'[columns in file]',
		                 -tmp     =>'/tmp',
                                 -verbose  => 100);

 Function: Parses new mp3s and adds them to a pre-existing database,
 Returns : true if succesful
 Args    : array of top-level paths to new mp3s; path to tmp directory
 Status  : Public
  
<B>update_database<B> accepts the same parameters and is a similar in
function to load_database except that it takes a path to new mp3s and
adds them to a preexisting database.  The artist and album of these
new files will be checked against those already existing in the
database to prevent addition of duplicates.  Duplicate songs, however,
will be added.  This is a feature, since you may want multiple copies
of some tracks. It's up to you in advance to remove duplicates if you
don't want them listed in your database. See the section below
"Appending To A Preexisting Database" for more information on using
this method.

The optional -verbose flag will a variety of messages to be displayed
to STDERR during processing. The value of -verbose controls how
frequently to display a message during song processing.

Like load_database, update_database can read information directly from
flat files instead of the MP3s themselves. See load_database for more
information.

=head1 Additional Public Methods

Audio::DB;:Build contains several additional public methods that you are
welcome to use if you'd like greater control over file parsing and
database loading.  In the normal course of things, you probably will
not need to use these methods directly but are described for
completeness.

=head2 cache_song

 Title   : cache_song
 Usage   : $mp3->cache_song(-full_path=>$full_path,-file=>$file);
           $mp3->cache_song(-song=>$song);
 Function: Parses new mp3s and adds them to a pre-existing database
 Returns : true if successful
 Args    : a pre-processed data hash arising from one of the Parse modules
 Status  : Public

cache_song accepts the filename and full path to a file to be
processed. It makes seperate calls to MP3::Info to extract ID3 tag
info. Once extracted, song information is checked against the database
to determine if the artist or album have been seen before, adding the
song to that artist or album or inserting new artists / albums into
the internal temporary data structure as required.  Finally, the song
is added to this structure.

Alternatively, cache_song can be passed a single tab-delimited line of
data that holds the relevant information. See load_database for more
information and using this interface.

=head2 get_couldnt_read

 Title   : get_couldnt_read
 Usage   : $mp3->get_couldnt_read()
 Function: Fetch a list of files that could not be read
 Returns : Array reference of files whose tags could not be read
 Args    : none
 Status  : Public

=head2 get_stats

 Title   : get_stats
 Usage   : $mp3->get_stats;
 Function: Get some info on files loaded
 Returns : Hash reference containing the number of artists,
           albums, genres, and songs loaded into the database.
 Args    : none
 Status  : Public

=head1 Private Methods

There are a number of private methods, described here for my own sanity.
These methods are not part of the public interface.

=head2  _establish_counters

 Title   : _establish_counters
 Usage   : $mp3->_establish_counters
 Function: Used to determine the highest values for keys before adding
           new data to the database.
 Returns : Hash reference containing the number of artists,
           albums, genres, and songs loaded into the database.
 Args    : none
 Status  : Private

=head2 get_tags

 Title   : get_tags
 Usage   : $mp3->get_tags(@args);
 Function: Fetch and processes raw ID3 tags from files
 Returns : Hash reference of parsed tag data
 Status  : Private

=head2 _check_*_mem, _check_*_db

  _check_artist_mem _check_album_mem 
  _check_genre_mem _check_artist_db
  _check_album_db _check_genre_db

 Title   : _check_*_mem or _check_*_db
 Usage   : $mp3->_check_album_mem($artist);
 Function: Checks for the existence of the current tag
 Returns : ID of the appropriate album, artist, genre, if it already exists
 Args    : artist, album, or genre, as appropriate
 Status  : Private

The _check_* methods check for the pre-existence of the current
artist, album, or genre for the file currently being examined. The two
variations, *_mem and *_db, control whether this look up is done
against the internal data structure in memory or against a
pre-existing database.

_check_album_* is necessarily more complex. It attempts to assign
songs to albums based on both the year and total number of tracks. See
"Caveats" above for more information.

=head2 _dump_data_structures

 Title   : _dump_data_structures
 Usage   : _dump_data_structures
 Function: Wrapper around all the _dump_* subroutines
 Returns : true if succesful
 Args    : none
 Status  : Private

=head2 _dump_*

  _dump_artists  _dump_albums
  _dump_songs    _dump_genres

 Title   : _dump_*
 Usage   : _dump_artists()
 Function: Create temp files for loading into the database
 Returns : true if succesful
 Args    : none
 Status  : Private

These methods dump out the appropriate data from the internal data
structure into the temporary  directory path. Some dump multiple tables: 

  _dump_artists : artists and artist_genres tables 
  _dump_albums  : album and album_artists tables
  _dump_songs   : songs table
  _dump_genres  : genres table

=head2 _load_db

 Title   : _load_db
 Usage   : _load_db()
 Function: Loads data from temporary tables into the database
 Returns : true if succesful
 Args    : none
 Status  : Private

=head2 _stuff_album

 Title   : _stuff_album
 Usage   : _stuff_album()
 Function: Stuffs the current album into the internal data structure
 Returns : true if succesful
 Args    : none
 Status  : Private

=head1 Internal Data Structure

Audio::DB::Build builds a large internal data structure as it reads each file.
The data strucutre is:

 Lookups - For quick lookups to see if an artist, album or genre has been encountered
 $self->{lookups}->{artists}->{$artist} = $artist_id;
 $self->{lookups}->{albums}->{$album}   = $album_id;
 $self->{lookups}->{songs}->{$song}     = $song_id;
 $self->{lookups}->{songs}->{$genre}    = $genre_id;

 Counters - for tracking the number of artists, albums, songs, and genres
 $self->{counters}->{artists}= $total;
 $self->{counters}->{albums} = $total;
 $self->{counters}->{songs}  = $total;
 $self->{counters}->{genres} = $total;

 $self->{couldnt_read} = [ files that could not be read ];

The main data structure of artists, albums, songs, and genres
I know, I know, its partially denormalized.

 $self->{artists}->{$artist_id} = { artist => artist name,
		  		    genres => { $genre_ids => total },
				    albums => { $album => $album_id }
				};

 $self->{albums}->{$album_id} = { album     => $album,
          # For tracking multiple genres per album
				  genres    => { $genre_ids => ++ },
	  # For tracking multiple artists per album (compilation CDs)
          			  contributing_artists  => { $artist_id => ++ },
          # Internal measure for distinguishing same-named albums
                                  total_tracks => total number of tracks,
				  year         => year released
			      };

 $self->{songs}->{$song_id} = { title        => song title,
	                        artist_id    => artist_id,
			        album_id     => album_id,
			        genre_id     => genre_id,
			        track        => track number,
			        total_tracks => total tracks on album,
			        duration     => formatted duration,
			        seconds      => raw seconds,
			        bitrate      => song bitrate,
			        samplerate   => sample rate,
			        comment      => id3 comment,
			        filename     => filename,
			        filesize     => filesize,
			        filepath     => filepath,
			        tagtypes     => types of ID3 tags found,
			        format       => MPEG layer,
			        channels     => stereo / mono / joint,
			        song_year    => year (also with album),
			        rating       => user rating,
			        playcount    => play count }

 $self->{genres}->{$genre_id} = { genre => $genre }

=head1 BUGS

This module implements a fairly complex internal data structure,
which in itself rests upon lots of things going right, like reading ID3 tags,
tag naming conventions, etc. On top of
that, I wrote this in a Starbucks full of screaming children.


=head1 TODO

Need a resonable way of dealing with tags that can't be read

Lots of error checking needs to be added.  Support for custom data schemas,
including new data types like more extensive artist info, paths to images,
etc.

Keep track of stats for updates.
Fix update - needs to use mysql (these are the _check_artist_db routines that
all need to be implemented)

Robusticize new for different adaptor types

Add in full MP4 support
make the data dumps rely on the schema in the module
put the schema into its own module

=head1 AUTHOR

Copyright 2002-2004, Todd W. Harris <harris@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.


=head1 ACKNOWLEDGEMENTS

Chris Nandor <pudge@pudge.net> wrote MP3::Info, the module responsible for 
reading MP3 tags. Without, this module would be a best-selling pulp
romance novel behind the gum at the grocery store checkout. Chris has
been really helpful with issues that arose with various MP3 tags from 
different taggers. Kudos, dude!

Lincoln (Dr. Leichtenstein) Stein <lstein@cshl.org> wrote much of the original 
adaptor code as part of the l<Bio::DB::GFF> module. Much of that code is 
incorporated here, albeit in a pared-down form.  The code for reading ID3 tags 
from files only with appropriate MIME-types is borrowed from his <Apache::MP3> 
module. This was a much more elegant than my lame solution of checking for .mp3!
Lincoln tolerates having me in his lab, too, even though I use a Mac.

=head1 SEE ALSO

L<Audio::DB::Adaptor::dbi::mysql>,L<Audio::DB::Util::Reports>,
L<Apache::MP3>, L<Apache::Audio::DB>,L<MP3::Info>

=cut

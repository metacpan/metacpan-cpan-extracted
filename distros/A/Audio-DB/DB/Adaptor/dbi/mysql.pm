package Audio::DB::Adaptor::dbi::mysql;

# VERSION: $Id: mysql.pm,v 1.2 2005/02/27 16:56:25 todd Exp $

use strict;
use DBI;

use Audio::DB::Util::Rearrange;
use Audio::DB::DataTypes::Song;

use vars qw($VERSION);

$VERSION = '1.11';

use constant MYSQL => 'mysql';

my %queries = (
	       # Get a count of the distinct albums so 
	       # information can easily be presented on
	       # a preliminary page without additional queries

	       # THESE PAN QUERIES COULD BE USEFUL LATER ON....
	       # Find all uniqe albums that an artist contributes to
	       artist => qq{select *,COUNT(DISTINCT album) 
			    from artists,album_artists,albums 
			    where artist REGEXP ? 
			    and artists.artist_id=album_artists.artist_id 
			    and album_artists.album_id=albums.album_id 
			    GROUP by artist ORDER BY artist},
	       
	       # Group on album_id to keep from clobbering
	       # albums of the same name
		 album  => qq{select * from albums,album_artists,artists
			      where album REGEXP ? 
			      and albums.album_id=album_artists.album_id
			      and album_artists.artist_id=artists.artist_id 
			      GROUP BY albums.album_id ORDER BY album},
	       
	       song  => qq{select * from songs,artists,albums
			   where song REGEXP ?
			   and songs.artist_id=artists.artist_id
			   and songs.album_id=albums.album_id
			   GROUP by title ORDER by title}
	      );


=head2 new

Title   : new
  Usage   : $db = Audio::DB->new(@args)
 Function: create a new adaptor
  Returns : an Audio::DB object
  Args    : see below 
  Status  : Public
  
  Argument    Description
  --------    -----------
  -dsn        the DBI data source, e.g. 'dbi:mysql:music_db' or "music_db"
  Also accepts DB or database as synonyms.
  -user       username for authentication
  -pass       the password for authentication

=cut

sub new {
  my ($class,@args) = @_;
  my ($db,$host,$user,$auth,$create)
    = rearrange([
  		 [qw(DB DSN DATABASE)],
  		 [qw(HOST)],
  		 [qw(USERNAME USER)],
  		 [qw(PASSWORD PASS)],
		 'CREATE'
  		],@args);
  
  my $host ||= 'localhost';
  _create_database($user,$auth,$host,$db) if ($create);
  my $music_db;

  if ($auth && $user) {
    $music_db = DBI->connect("dbi:mysql:$db" . ';host=' . $host,$user,$auth)
  } elsif ($user) {
    $music_db = DBI->connect("dbi:mysql:$db" . ';host=' . $host,$user);
  } else {
    $music_db = DBI->connect("dbi:mysql:$db" . ';host=' . $host);
  }

  $music_db or  die "Couldn't connect to the database $db\n";
  # fill in object, bless it, and send us on our way
  return bless { dbh => $music_db },$class;
}


################################ loading, initialization, schema ##################################

=head2 _create_database

Title   : _create_database
  Usage   : _create_database(user,pass,host,db)
 Function: create the database
  Returns : a boolean indicating the success of the operation
  Args    : username, password, host and database
  Status  : protected

Called internally by new to create the database
if it does not already exist.

=cut

# Create the schema from scratch.
# You will need create privileges for this.
sub _create_database {
  my ($user,$auth,$host,$db) = @_;
  my $success = 1;
  my $command =<<END;
${\MYSQL} -u $user -p$auth -h $host -e "create database $db"
END
;
$success && system($command) == 0;
die "Couldn't create the database $db" if !$success;
}


=head2 do_initialize

 Title   : do_initialize
 Usage   : $success = $db->do_initialize($drop_all)
 Function: initialize the database
 Returns : a boolean indicating the success of the operation
 Args    : a boolean indicating whether to delete existing data
 Status  : protected

This method will load the schema into the database.  If $drop_all is
true, then any existing data in the tables known to the schema will be
deleted.

Internally, this method calls schema() to get the schema data.

=cut

sub do_initialize {
  my $self = shift;
  my $erase = shift;
  $self->drop_all if $erase;

  my $dbh = $self->dbh;
  my ($schema,$raw_schema) = $self->schema;
  foreach (values %$schema) {
    $dbh->do($_) || warn $dbh->errstr;
  }
  1;
}


=head2 drop_all

 Title   : drop_all
 Usage   : $dbh->drop_all
 Function: empty the database
 Returns : void
 Args    : none
 Status  : protected

This method drops the tables known to this module.  Internally it
calls the abstract tables() method to get a list of all tables to
drop.

=cut

# Drop all the tables -- dangerous!
sub drop_all {
  my $self = shift;
  my $dbh = $self->dbh;
  local $dbh->{PrintError} = 0;
  foreach ($self->tables) {
    $dbh->do("drop table $_");
  }
}


# return list of table names.

=head2 tables

 Title   : tables
 Usage   : @tables = $db->tables
 Function: return list of tables that belong to this module
 Returns : list of tables
 Args    : none
 Status  : protected

This method returns a list of all the tables in the database.

=cut

sub tables {
  my ($schema,$raw_schema) = shift->schema;
  return keys %$schema;
}


=head2 schema

 Title   : schema
 Usage   : ($schema,$raw_schema) = $mp3->schema
 Function: return the CREATE script for the schema and 
           the raw_schema as a hashref
           for easily accessing columns in proper order.
 Returns : a hash of CREATE statements; hash of tables and parameters
 Args    : none
 Status  : protected

This method returns a list containing the various CREATE statements
needed to initialize the database tables. Each create statement
is built programatically so I can maintain all fields in a central
location . This raw schema is returned for building temporary tables 
for loading.

=cut

sub schema {
  my $tables = {};
  
  push (@{$tables->{artists}},
	{  artist_id  =>  'int not null auto_increment' },
	{  artist     =>  'text'                        },
	{ 'primary key(artist_id)' => 1                 },
	{ 'INDEX(artist(12))'      => 1                 }
       );

  push (@{$tables->{albums}},
	{  album_id      =>  'int not null auto_increment'    },
	{  album         =>  'text'                           },
	{  type          =>  "ENUM('compilation','standard')" },
	{  total_tracks  =>  'int'                            },
	{  year          =>  'text'                           },
	{ 'primary key(album_id)' => 1                        },
	{ 'INDEX(album(12))'      => 1                        },
	{ "INDEX(year(8))"        => 1                        }
       );
  
  push (@{$tables->{songs}},
	{  song_id         =>     'int not null auto_increment' },
	{  title           =>     'text' },
	{  artist_id       =>     'int'  },
	{  album_id        =>     'int'  },
	{  genre_id        =>     'int'  },
	{  track           =>     'int'  },
	{  duration        =>     'text' },
	{  seconds         =>     'int'  },
	{  lyrics          =>     'text' },
	{  comment         =>     'text' },
	{  bitrate         =>     'int'  },
	{  samplerate      =>     'real' },
	{  fileformat      =>     'text' },
	{  channels        =>     'text' },
	{  tagtypes        =>     'text' },
	{  filename        =>     'text' },
	{  filesize        =>     'real' },
	{  filepath        =>     'text' },
	{  year            =>     'text' },
        {  uber_rating     =>     'int'  },
        {  uber_playcount  =>     'int'  },
	{ 'primary key(song_id)' => 1    },
	{ 'INDEX(title(10))'                        => 1   },
	{ 'INDEX(year(8))'                          => 1   },
	{ 'INDEX(uber_playcount)'  => 1   },
	{ 'INDEX(uber_rating)'     => 1   },
	{ 'INDEX(album_id)'        => 1   },
	{ 'INDEX(artist_id)'       => 1   },
	{ 'INDEX(genre_id)'        => 1   },
       );
  
  push (@{$tables->{album_artists}},
	{ artist_id      =>     'int not null'   },
	{ album_id       =>     'int not null'   },
	{ 'primary key(artist_id,album_id)' => 1 });
  
  push (@{$tables->{genres}},
	{ genre_id       =>     'int not null auto_increment' },
	{ genre          =>     'text'                        },
	{ 'primary key(genre_id)' => 1                        },
	{ 'INDEX(genre(10))'      => 1                        },
       );

  push (@{$tables->{artist_genres}},
	{ artist_id      =>   'int not null'  },
	{ genre_id       =>   'int not null'  },
	{'primary key(artist_id,genre_id)' => 1});

  push (@{$tables->{song_genres}},
	{ song_id    =>     'int not null'   },
	{ genre_id   =>     'int not null'   },
	{'primary key(song_id,genre_id)' => 1 });
		
  push (@{$tables->{song_types}},
	{ song_id    =>      'int not null' },
	{ type       =>      "ENUM('live','cover','bootleg','single') not null" },
	{'primary key(song_id)' => 1   });

  # The following tables are for maintaining users and playlists
  push (@{$tables->{users}},
	{ user_id     =>      'int not null auto_increment' },
	{ first       =>      'text' },
	{ last        =>      'text' },
	{ email       =>      'text' },
	{ username    =>      'text' },
	{ password    =>      'text' },
	{ privs       =>      'text' },
	{ joined      =>      'timestamp' },
	{ last_access  =>     'date' },
	{ songs_played =>     'int'  },
       	{'primary key(user_id)' => 1 },
	{'UNIQUE(username(8))'  => 1 });

  push (@{$tables->{user_ratings}},
	{ user_id     =>      'int not null' },
	{ song_id     =>      'int not null' },
	{ rating      =>      'int'          },
	{ playcount   =>      'int'          },
	{'primary key(user_id,song_id)' => 1 },
	{ 'INDEX(rating)'               => 1 },
	{ 'INDEX(playcount)'            => 1 },
       );
	
  push (@{$tables->{playlists}},
	{ playlist_id     =>      'int not null auto_increment' },
	{ playlist        =>      'text' },
	{ description     =>      'text' },	
	{ user_id         =>      'int not null' },   # each playlist has to belong to someone
	{ is_shared       =>      "ENUM('yes','no')" },
	{ created         =>      'date' },
	{ viewed          =>      'int'  },
	{'primary key(playlist_id)' => 1 },
	{ 'INDEX(playlist(10))'     => 1 },
       );

  push (@{$tables->{playlist_songs}},
	{ playlist_id     =>      'int not null' },
	{ song_id         =>      'int not null' },
	{'primary key(playlist_id,song_id)' => 1 });

  my %schema;
  foreach my $table (keys %$tables) {
    my $create = "create table $table (";
    my $count;
    foreach my $param (@{$tables->{$table}}) {
      $count++;
      # Append a comma to the previous entry, but only if this
      # isn't the first...
      $create .= ',' if ($count > 1);
      
      my ($key) = keys %$param;
      my ($val) = values %$param;
      if ($val == 1) {
	$create .= $key;
      } else {
	$create .= $key . ' ' . $val;
	# $create .= $key . ' ' . $val . ',';
      }
    }
    $create .= ')';
    $schema{$table} = $create;
  }
  return (\%schema,$tables);
}


### NOT YET IMPLEMENTED
###=head2 finish_load
#
# Title   : finish_load
# Usage   : $db->finish_load
# Function: called after load_gff_line()
# Returns : number of records loaded
# Args    : none
# Status  : protected

#This method performs schema-specific cleanup after loading a set of
#MP3 records.  It finishes each of the statement handlers prepared by
#setup_load().
#
#=cut
#
#### NOT USING
#sub finish_load {
#  my $self = shift;
#
#  my $dbh = $self->features_db or return;
#  $dbh->do('UNLOCK TABLES') if $self->lock_on_load;
#
#  foreach (keys %{$self->{load_stuff}{sth}}) {
#    $self->{load_stuff}{sth}{$_}->finish;
#  }
#
#  my $counter = $self->{load_stuff}{counter};
#  delete $self->{load_stuff};
#  return $counter;
#}


=head2 dbh

 Title   : dbh
 Usage   : $dbh->dbh
 Function: get database handle
 Returns : a DBI handle
 Args    : none
 Status  : Public

=cut


sub dbh      { shift->{dbh} }


=head2 DESTROY

 Title   : DESTROY
 Usage   : $dbh->DESTROY
 Function: disconnect database at destruct time
 Returns : void
 Args    : none
 Status  : protected

This is the destructor for the class.

=cut

sub DESTROY {
  my $self = shift;
  $self->dbh->disconnect if defined $self->dbh;
}


=head2 debug

 Title   : debug
 Usage   : $dbh = $dbh->debug
 Function: prints out debugging information
 Returns : debugging information
 Args    : none
 Status  : Private

=cut

sub debug {
  my $self = shift;
  $self->dbh->debug(@_);
  $self->SUPER::debug(@_);
}






##################
# QUERIES
##################
# Used to find out the id of the last value inserted
# for building databases...
sub lookup_counter {
  my ($self,$field,$table) = @_;
  my $dbh = $self->dbh;
  my $sth = $dbh->prepare(qq{select $field from $table ORDER BY $field DESC LIMIT 1});
}


#### NEW SUB
# This might come in handy later
# SOME OF THIS COULD BE MIGRATED OUT
# Generically fetch an item for a single table by its ID
# MIGRATE TO QUERY
# DEPRECATING
sub fetch_by_id {
  my ($self,$class,$id) = @_;
  my $dbh = $self->dbh;
  my $table = $class;
  $table =~ s/s$//;
  my $sth = $dbh->prepare(qq{select * from $class where $class.$table\_id=?});
  $sth->execute($id) or warn $sth->errstr;
  my $h = $sth->fetchrow_hashref;
  return $h;
}
## END NEW



# RETAIN
# Generic queries that should be part of each adaptor
# queries are grouped by the predominant class of object they are intended to retrieve
# This approach is not as clever as that which used generic fetch_class type subroutines.
# On the other hand, it allows for more tailored queries that let me build up more informative data structures

sub artist_queries {
  my ($self,$query,$table) = @_;
  my $dbh = $self->dbh;
  # BY IDs
  # Easiest case: Fetch an artist by its ID (returns a single result)
  if ($query eq 'by_artist_id') {
    return ($dbh->prepare(qq{select * from artists where artist_id=?}));
  }

  # Fetch an artist by an album ID (may possibly return more than one result)
  if ($query eq 'by_album_id') {
    return ($dbh->prepare(qq{select * from album_artists,artists where album_artists.album_id=? and album_artists.artist_id=artists.artist_id}));
  }

  # Fetch artist by a song ID (should return one and only one result)
  if ($query eq 'by_song_id') {
    return ($dbh->prepare(qq{select * from songs,artists where songs.song_id=? and songs.artist_id=artists.artist_id}));
  }

  # Fetch all artists associated with a given genre (may return multiple results)
  if ($query eq 'by_genre_id') {
    return ($dbh->prepare(qq{select * from artist_genres,artists where artist_genres.genre_id=? and artist_genres.artist_id=artists.artist_id}));
  }
  
  # BY TEXT-BASED QUERIES
  # Fetch an artist by name (possibly returns multiple entries)
  if ($query eq 'by_artist') {
    return ($dbh->prepare(qq{select * from artists where artist REGEXP ?}));
  }

  # Fetch all artists associated with an album title (possibly returns multiple entries)
  if ($query eq 'by_album') {
    return ($dbh->prepare(qq{select *
			     from albums,album_artists,artists
			     where albums.album REGEXP ? 
			     and albums.album_id=album_artists.album_id
			     and album_artists.artist_id=artists.artist_id}));
  }

  # Fetch an artist by a song title (possibly returns multiple entries)
  if ($query eq 'by_song') {
    return ($dbh->prepare(qq{select * songs,artists 
			     where songs.title REGEXP ? 
			     and songs.artist_id=artists.artist_id}));
  }

  # Fetch an artist by a genre (possibly returns multiple entries
  if ($query eq 'by_genre') {
    return ($dbh->prepare(qq{select * genres,artist_genres,artists
			     where genres.genre REGEXP ? 
			     and genres.genre_id=artist_genres.genre_id
			     and artist_genres.artist_id=artists.artist_id}));
  }

  # Find all artists with multiple genres assigned
  if ($query eq 'artists_multiple_genres') {
    return ($dbh->prepare(qq{select artist_genres.artist_id,count(artist_genres.artist_id) as total_genres,artist from artist_genres,artists where artist_genres.artist_id=artists.artist_id GROUP BY artists.artist_id HAVING total_genres > 1}));
  }
}

sub song_queries {
  my ($self,$query,$table) = @_;
  my $dbh = $self->dbh;

  # BY IDs
  # Easiest case: Fetch a song by its ID (returns a single result)
  if ($query eq 'by_song_id') {
    return ($dbh->prepare(qq{select * from songs where song_id=?}));
  }

  # Find all songs associated with a given album id
  # Do a join to artists for convenience
  if ($query eq 'by_album_id') {
    return ($dbh->prepare(qq{select * from songs,artists where songs.album_id=? and songs.artist_id=artists.artist_id}));
  }

  # Fetch all songs associated with a given artist ID (not typically used)
  if ($query eq 'by_artist_id') {
    return ($dbh->prepare(qq{select * from songs where artist_id=?}));
  }

  # Fetch all songs associated with a given genre (may return multiple results)
  # Not typically used as this data needs to be aggregated first
  if ($query eq 'by_genre_id') {
    return ($dbh->prepare(qq{select * from genres,artist_genres,songs where genres.genre_id=? and genres.genre_id=artist_genres.genre_id and artist_genres.artist_id=songs.artist_id}));
  }
  
  # BY TEXT-BASED QUERIES
  # Fetch a song by name (possibly returns multiple entries)
  if ($query eq 'by_song') {
    return ($dbh->prepare(qq{select * from songs where title REGEXP ?}));
  }
  # Fetch all songs associated with an album title (possibly returns multiple entries)
  # Not typically used
  if ($query eq 'by_album') {
    return ($dbh->prepare(qq{select *
			     from albums,songs
			     where albums.album REGEXP ? 
			     and albums.album_id=songs.album_id}));
  }

  # Fetch all songs associated with a given artist
  # NOT TYPICALLY USED
  if ($query eq 'by_artist') {
    return ($dbh->prepare(qq{select * artists,songs
			     where artists.artist REGEXP ?
			     and artists.artist_id=songs.artist_id}));
  }
  
  # Fetch all songs associated with a given genre (possibly returns multiple entries
  # Not typically used
  if ($query eq 'by_genre') {
    return ($dbh->prepare(qq{select * genres,artist_genres,songs
			     where genres.genre REGEXP ? 
			     and genres.genre_id=artist_genres.genre_id
			     and artist_genres.artist_id=songs.artist_id}));
  }

  # PAN QUERY TO SPEED UP REPORT
  # Find all artists with multiple genres assigned
  if ($query eq 'artists_multiple_genres') {
    return ($dbh->prepare(qq{select artist_id,count(artist_id) as total_genres from artist_genres GROUP BY artist_id HAVING total_genres > 1}));
  }

  # Used for Reports::distribution()
  # Find all the songs released in a given year
  if ($query eq 'songs_per_year') {
    return ($dbh->prepare(qq{select count(*) from songs where year=?}));
  }
}

sub album_queries {
  my ($self,$query,$table) = @_;
  my $dbh = $self->dbh;
  # BY IDs
  # Easiest case: Fetch an album by its ID (returns a single result)
  if ($query eq 'by_album_id') {
    return ($dbh->prepare(qq{select * from albums where album_id=?}));
  }

  # Fetch an album by an artist ID (may possibly return more than one result)
  if ($query eq 'by_artist_id') {
    return ($dbh->prepare(qq{select * from album_artists,albums where album_artists.artist_id=? and album_artists.album_id=albums.album_id}));
  }

  # Fetch album by a song ID (should return one and only one result)
  if ($query eq 'by_song_id') {
    return ($dbh->prepare(qq{select * from songs,albums where songs.song_id=? and songs.album_id=albums.album_id}));
  }

  #  # Fetch all albums associated with a given genre (may return multiple results)
  if ($query eq 'by_genre_id') {
    return ($dbh->prepare(qq{select *,count(*) as total_albums from songs,albums where songs.genre_id=? and songs.album_id=albums.album_id GROUP BY albums.album}));
  }
  
  # BY TEXT-BASED QUERIES
  # Fetch an album by name (possibly returns multiple entries)
  if ($query eq 'by_album') {
    return ($dbh->prepare(qq{select * from albums where album REGEXP ?}));
  }

  # Fetch all albums associated with an artist (possibly returns multiple entries)
  if ($query eq 'by_artist') {
    return ($dbh->prepare(qq{select *
			     from artists,album_artists,albums
			     where artists.artist REGEXP ? 
			     and artists.artist_id=album_artists.artist_id
			     and album_artists.album_id=albums.album_id}));
  }

  # Fetch an artist by a song title (possibly returns multiple entries)
  if ($query eq 'by_song') {
    return ($dbh->prepare(qq{select * songs,albums
			     where songs.title REGEXP ? 
			     and songs.album_id=albums.album_id}));
  }

  # THIS IS NOT PARTICULARLY APPLICABLE
  #  # Fetch an artist by a genre (possibly returns multiple entries
  #  if ($query eq 'by_genre') {
  #    return ($dbh->prepare(qq{select * genres,artist_genres,artists
  #			     where genres.genre REGEXP ? 
  #			     and genres.genre_id=artist_genres.genre_id
  #			     and artist_genres.artist_id=artists.artist_id}));
  #  }

  # Find all albums that have *any* songs below a given bitrate threshold
  if ($query eq 'albums_below_bitrate_threshold') {
    return ($dbh->prepare(qq{select * from songs,albums where bitrate < ? and songs.album_id=albums.album_id GROUP BY albums.album_id}));
  }

  # Find all the albums released in a given year
  if ($query eq 'albums_per_year') {
    return ($dbh->prepare(qq{select count(*) from albums where year=?}));
  }
}


sub genre_queries {
  my ($self,$query,$table) = @_;
  my $dbh = $self->dbh;

  # BY IDs
  # Easiest case: Fetch a genre by its ID (returns a single result)
  if ($query eq 'by_genre_id') {
    return ($dbh->prepare(qq{select * from genre where genre_id=?}));
  }

  # Find all genres associated with a given album id
  # Do a join to artists for convenience
  if ($query eq 'by_album_id') {
    return ($dbh->prepare(qq{select genre,genres.genre_id from
			     album_artists,artist_genres,genres
			     where album_artists.album_id=?
			     and album_artists.artist_id=artist_genres.artist_id
			     and artist_genres.genre_id=genres.genre_id 
			     GROUP BY genre}));
  }

  # Fetch all genres associated with a given artist ID
  if ($query eq 'by_artist_id') {
    return ($dbh->prepare(qq{select genre,genres.genre_id 
			     from genres,artist_genres
			     where artist_genres.artist_id=? and
			     artist_genres.genre_id=genres.genre_id}));


    return ($dbh->prepare(qq{select * from songs where artist_id=?}));
  }

  # Fetch the genre for a given song
  if ($query eq 'by_song_id') {
    return ($dbh->prepare(qq{select * from songs where genre_id=?}));
  }
  
  # BY TEXT-BASED QUERIES
  # Fetch a genre by name (possibly returns multiple entries)
  if ($query eq 'by_genre') {
    return ($dbh->prepare(qq{select * from genres where genre REGEXP ?}));
  }
  # Fetch all genres associated with an album title (possibly returns multiple entries)
  # Not typically used
  if ($query eq 'by_album') {
    return ($dbh->prepare(qq{select *
			     from genres,songs,albums
			     where albums.album REGEXP ? 
			     and albums.album_id=songs.album_id and songs.genre_id=genres.genre_id GROUP BY genres.genre}));
  }

  # Fetch all genres associated with a given artist
  if ($query eq 'by_artist') {
    return ($dbh->prepare(qq{select * from artists,artist_genres
			     where artists.artist REGEXP ?
			     and artists.artist_id=artist_genres.artist_id
			     and artist_genres.genre_id=genres.genre_id}));
  }
  
  # Fetch the genre for a specific song
  if ($query eq 'by_song') {
    return ($dbh->prepare(qq{select * songs,genres
			     where songs.title REGEXP ? 
			     and songs.genre_id=genres.genre_id}));
  }
  
  # PAN QUERY TO SPEED UP REPORT
  # Find all artists with multiple genres assigned
  if ($query eq 'artists_multiple_genres') {
    return ($dbh->prepare(qq{select artist_id,count(artist_id) as total_genres from artist_genres GROUP BY artist_id HAVING total_genres > 1}));
  }
  
  if ($query eq 'all_genres') {
    return ($dbh->prepare(qq{select * from genres}));
  }

  # Used for Reports::distribution()
  # Find all the songs released in a given year
  if ($query eq 'songs_per_year') {
    return ($dbh->prepare(qq{select count(*) from songs where year=?}));
  }
}


sub generic_queries {
  my ($self,$query,$table) = @_;
  my $dbh = $self->dbh;
  # USED BY Query::fetch_class
  return ($dbh->prepare(qq{select * from $table})) if ($query eq 'fetch_class');

  # Return a count of all items within a provided table
  if ($query eq 'simple_count') {
    return ($dbh->prepare(qq{select count(*) from $table}));
  }

}




# Fetch the sum of seconds or total file size
# UPDATED
sub query_for_total {
  my ($self,$field) = @_;
  my $dbh = $self->dbh;
  my $sth = $dbh->prepare(qq{select sum($field) from songs});
  $sth->execute();
  my ($sum) = $sth->fetchrow_array;
  return $sum;
}


# DEPRECATING
sub fetch_by_letter {
  my ($self,$letter,$class) = @_;
  my $dbh = $self->dbh;
  my $sth = $dbh->prepare($queries{$class});
  $sth->execute($letter);
  return $sth;
}

# DEPRECATING
sub generic_search {
  my ($self,@p) = @_;
  my ($class,$query,$container) = rearrange([qw/CLASS QUERY CONTAINER/],@p);
  
  my $dbh = $self->dbh;
  my $sth = $dbh->prepare($queries{$class});
  $sth->execute($query);
  
  my $temp = 'Audio::DB::DataTypes::' . ucfirst $class;
  while (my $h = $sth->fetchrow_hashref) {
    my $obj = $temp->new(-summary=>$h);
    
    # pluralize whatever is returned.  Stupid complication
    # Why do I do this?
    push (@{$container->{$class . 's'}},$obj);
  }
  
  # What if only one item was returned?
  # Should I directly shunt into the single item object method?
  # I should probably be able to get this information from rows or something...
  
  if (scalar (@{$container->{$class . 's'}} == 1)) {
    # Fetch out the single object returned so that I can pass it in...
    my $original = $container->{$class . 's'}[0];
    
    # Quick fetch of the class and ID that I am trying to fetch...
    my $coderef = $class . '_id';
    my $obj = $temp->new(-adaptor => $self->adaptor,
			 -id      => $original->$coderef);
    return $obj;
  }
  return $container;
}

=pod

=head1 NAME

Audio::DB::Adaptor::dbi::mysql -- Database adaptor for a specific mysql schema

=head1 SYNOPSIS

See L<Audio::DB>

=head1 DESCRIPTION

This adaptor implements a specific mysql database schema that is
compatible with Audio::DB.  It inherits from Audio::DB.  In addition 
to implementing the abstract SQL-generating methods of
Audio::DB::Adaptor::dbi, this module also implements the data
loading functionality of Audio::DB.

The schema uses several tables:

B<artists>
  This the artists data table. Its columns are:

artist_id	  artist ID (integer); primary key
  artist          artist name (string); may be null; indexed

B<albums>
  This is the albums table. Its columns are:

  album_id        album ID (integer); primary key
  album           album name (string); may be null; indexed
  album_type      one of compilation or standard; may be null
  total_tracks    total songs on album (integer)
  year            self explanatory, no? (integer)

B<songs>
  This is the primary songs table. Its columns are:

  song_id         song ID (integer); primary key
  title           song title (string)
  artist_id       artist ID (integer); indexed
  album_id        album ID (integer)
  genre_id        genre ID (integer) # may be superceded...see note
  track           track number (integer)
  duration        formatted song length (string)
  seconds         length in seconds (integer)
  lyrics          song lyrics (long text)
  comment         ID3 tag comment (text)
  bitrate         encoded bitrate (integer)
  samplerate      sample rate (real)
  format          format of the file (ie MPEG) (string)
  channels        channels (string)
  tag_types       type of ID3 tags present (ie ID3v2.3.0) (text)
  filename        file name (text)
  filesize        file size in bytes (real)
  filepath        absolute path (text)
  year            the year tag for single tracks 
                  (since singles or songs on compilations 
	           each may be different) (integer)
  uber_playcount  total times the song has been played
  uber_rating     overall song rating (see "users" below)
  
Currently, ID3 tags support but a single genre.  
The genre_id is now stored with the song table. Multiple 
genres may be assigned via the song_genres join table 
below. The 'year' is a database denormalization that 
allows the assignment of years to single tracks not 
belonging to an album.

B<genres>
  This is the genres table.  Its columns are:

  genre_id         genre ID (integer); primary key
  genre            genre (string)

B<album_artists>
  This is the album_artists join table. Its columns are:

  artist_id        artist ID. May not be null.
  album_id         album ID.  May not be null.

B<artist_genres>
  This is the artists_genres join table. It enables 
  multiple genres to be assigned to a single artist. 
  Its columns are:

  artist_id        artist ID. May not be null
  genre_id         genre ID.  May not be null

B<song_genres>
  This is the song_genres join table. It enables 
  multiple genres to be assigned to a single song. 
  Its columns are:

  song_id        artist ID. May not be null
  genre_id       genre ID.  May not be null

B<song_types>
  This is the song_types join table. It enables 
  multiple general descriptive types to be 
  assigned to a single song. Its columns are:

  song_id        artist ID. May not be null
  type           one of: live cover bootleg single

=head2 Supplementary tables used by Web.pm

  Audio::DB::Web provides a web interface to databases 
  created with Audio::DB.  It requires a few extra 
  tables that are not directly related to the MP3 
  tag data.

B<users>
  The users table provides support for multiple users 
  of the database. Its columns are:

  user_id      user UD. May not be null; primary key
  first        users first name (text)
  last         last name (text_
  email        email address (text)
  username     username in the system (text)
  password     password (text)
  privs        privileges (text)
  joined       date user joined (date)
  last_access  date of last access (timestamp)
  songs_played number of songs played (integer)

B<user_ratings>
  The user_ratings table allows users to maintain individual
  ratings and playcounts for every song (as opposed to the 
  uber playcounts and ratings above).  I'll probably pitch
  the uber columns above, instead determining these values in
  middleware.

  user_id         may not be null
  song_id         may not be null
  rating          user rating from 1-100 (integer)
  playcount       user playcount (integer)

B<playlists>
  Playlist names and descriptions. Columns are:

  playlist_id     may not be null; primary key
  playlist        the playlist name (text)
  description     brief description of the playlist (text)
  user_id         the owner of the playlist (integer)
  is_shared       yes/no. Controls the public-accessiblity of the playlist
  created         date playlist created. (date)
  viewed          number of times playlist viewed (integer)

B<playlist_songs>
  A small join table that associates songs with playlists:

  playlist_id     may not be null
  song_id         may not be null


=head2 Available Methods






=head1 BUGS

This module implements a fairly complex internal data structure,
which in itself rests upon lots of things going right, like reading ID3 tags,
tag naming conventions, etc. On top of
that, I wrote this in a Starbucks full of screaming children.

=head1 TODO

Lots of error checking needs to be added.  Support for custom data schemas,
including new data types like more extensive artist info, paths to images,
lyrics, etc.

Robusticize new for different adaptor types.

=head1 AUTHOR

Copyright 2002, Todd W. Harris <harris@cshl.org>.

This module is distributed under the same terms as Perl itself.  Feel
free to use, modify and redistribute it as long as you retain the
correct attribution.

=head1 ACKNOWLEDGEMENTS

Much of this module was derived from B<Bio::DB::GFF>, written by
Lincoln Stein <lstein@cshl.org>.

=head1 SEE ALSO

L<Audio::DB>,L<Audio::DB::Web>, L<Apache::MP3>

=cut



1;



package Audio::DB::Web;

# $Id: Web.pm,v 1.2 2005/02/27 16:56:25 todd Exp $

# ALL THE SQL queries need to be moved in dbi::mysql module

use strict 'vars';
use vars qw(@ISA $VERSION);
#use Apache::Constants qw(:common REDIRECT HTTP_NO_CONTENT);

use CGI qw/:standard *table *div *TR/;
use CGI::Cookie;

use DBI;
use Audio::DB;
use Audio::DB::Query;
use Audio::DB::Util::Rearrange;
use Audio::DB::Util::SystemConfig;
use Audio::DB::Util::Playlists;

use Audio::DB::DataTypes::Artist;
use Audio::DB::DataTypes::ArtistList;
use Audio::DB::DataTypes::Album;
use Audio::DB::DataTypes::AlbumList;
use Audio::DB::DataTypes::Genre;
use Audio::DB::DataTypes::GenreList;
use Audio::DB::DataTypes::Song;
use Audio::DB::DataTypes::SongList;

@ISA = qw/Audio::DB Audio::DB::Query/;

###################################################
# The new constructor is inherited from Audio::DB #
###################################################

# Farms out requests to various subs,
# creating the appropriate objects
sub process_requests {
  my $self = shift;
   return ($self->authenticate()) if (param('submit') eq 'Log In');
  
  # Nothing to process if the action is a 'tryin'
  # to retrieve the search form...passed as the 'search' value to the action key
  return if (url_param('action') eq 'search');
  
  # System Configuration, including user management
  return Audio::DB::Util::SystemConfig->new($self->dbh) if (url_param('admin'));
  
  # PLAYLISTS - Either trying to manipulate a playlist
  # by a form, grab it by a url...
  if (param('todo') eq 'add to playlist' || url_param('playlist')) {
    return Audio::DB::Util::Playlists->new($self->{dbh},$self->{user_id});
  } elsif (url_param('song_id')) {
    return ($self->_fetch_song);
  } else {
    # Searches from the form
    # Generating a coderef on the fly??
    my $coderef = 'search' if param('search_term');
    $coderef ||= url_param('action') . '_' . url_param('class') 
      if (url_param('action') && url_param('class'));
    if ($coderef) {
      my $results = $self->$coderef;
      return $results;
    }
  }
}



################################
# Generic database manipulation
################################
# Used for adding playlists and new users to the database...
# This is a generic variant of the add...
sub add_entry {
  my ($self,@p) = @_;
  my ($table,$msg,$detailed,$user_id) = rearrange([qw/TABLE SUCCESS_MSG DETAILED USER_ID/],@p);
  my $dbh = $self->{dbh};
  Delete('submit');
  
  my @params = param();
  my (@cols,@quoted);
  foreach (@params) {
    push (@quoted,$dbh->quote(param($_)));
    push (@cols,$_);
  }

  if ($user_id) {  
    push(@quoted,$user_id);
    push(@cols,'user_id');
  }

  my $result = $dbh->do("insert into " . $table . "("
			. join(",",@cols)
			. ") VALUES ("
			. join(",",@quoted) .")");
  if ($result) {
    print div({-class=>'success'},$msg);
    if ($detailed) {
      print start_div({-class=>'actioncontent'});
      my @ordered_params = qw/first_name last_name username password email joined privs/;
      
      print start_table(-width=>'50%');
      foreach (@ordered_params) {
	print TR(td($_),td(param($_)));
      }
      print end_table,end_div;
    }
  } else {
    $self->print_sql_error($dbh->errstr);
  }
}



# DEPRECATED BUT MAY BE USEFUL FOR GENERATING PAN QUERIES
## Should I expand the artist query?
#my %queries = (
#	       # Get a count of the distinct albums so 
#	       # information can easily be presented on
#	       # a preliminary page without additional queries
#	       artist => qq{select *,COUNT(DISTINCT album) 
#			    from artists,album_artists,albums 
#			    where artist REGEXP ? 
#			    and artists.artist_id=album_artists.artist_id 
#			    and album_artists.album_id=albums.album_id 
#			    GROUP by artist ORDER BY artist},
#	       
#	       # Group on album_id to keep from clobbering
#	       # albums of the same name
#	       album  => qq{select * from albums,album_artists,artists
#			    where album REGEXP ? 
#			    and albums.album_id=album_artists.album_id
#			    and album_artists.artist_id=artists.artist_id 
#			    GROUP BY albums.album_id ORDER BY album},
#
#	       song  => qq{select * from songs,artists,albums
#			   where song REGEXP ?
#			   and songs.artist_id=artists.artist_id
#			   and songs.album_id=albums.album_id
#			   GROUP by title ORDER by title}
#	      );



# SONG SEARCH NEEDS TO BE IMPLEMENTED
sub search {
  my $self = shift;
  
  my $class = lc param('class');
  my $query  = '.*' . param('search_term') . '.*';
  my $field = $class;
  
  # Create a generic container object of the appropriate class
  # to return the results
  my $this = bless { class=>ucfirst $field . 'List'},"Audio::DB::DataTypes::" .
    ucfirst param('class') . 'List';

  my $adaptor = $self->adaptor;
    $this = $adaptor->generic_search(-class=>$class,
  				   -query=>$query,
  #				   -container=>$container);
				     );
				     return $this;
}



##########################################
# Miscellaneous formatting and navigation
##########################################
# Some navigation tools
sub browse_navigation {
  my ($self,$msg) = @_;
  my @values = qw/0-9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
  my @links;
  foreach (@values) {
    # This should be a constant
    push @links,
      a({-href=>"/music.cgi?action=browse&class=$msg&$msg=$_"},$_);
  }
  return \@links;
}


# If provided with a blessed object, generate a link to that object
# Optionally provided with a class, will link to that
# if that psuedo class exists within the object
# It's also possible to just pass in a "fake" (non-blessed)
# object for linking...
sub build_url {
  my ($self,$class,$fake_object) = @_;
  $class ||= $self->{class};
  
  my ($link_text,$target);
  if ($fake_object) {
    $link_text = $fake_object->{$class};
    # Kludge for column name
    $link_text = $fake_object->{title} if ($class eq 'song');
    $target    = $fake_object->{$class . '_id'};
  } else {
    $link_text = $self->{$class};
    $target    = $self->{$class . '_id'};
    # Kludge for column name
    $link_text = $self->{title} if ($class eq 'song');
  }
  my $action  = url_param('action') || 'browse';
  my $primary = $class ."_id";
  
  $link_text =~ s/[<>]//g;
  $target    =~ s/[<>]//g;
 
  my $full_url = url();
  my $url = '<a href="' . $full_url .
    "?action=$action" . "&class=$class" . 
      "&$primary=$target"
	  .'">' . $link_text . "</A>";
}

# Build up some generic URL for navigation
sub build_nav_link {
  my ($self,@p) = @_;
  my ($class,$action,$text) = rearrange([qw/CLASS ACTION TEXT/],@p);
  my $url = url();
  my $link = a({-href=>$url . '?' . $class . '=' . $action},$text);
  return $link;
}


sub table_navigation {
  my ($self,@p) = @_;
  my ($type,$span) = rearrange([qw/TYPE SPAN/],@p);

  my @values = qw/# A B C D E F G H I J K L M N O P Q R S T U V W X Y Z/;
  print start_div({-class=>"navigation"});
  print start_table();
  my $count = 0;
  foreach (@values) {
    # End the previous row if necessary...
    if ($count == $span) {
      print end_TR;
      $count = 0;
    }
    
    if ($count == 0) {
      print start_TR({-class=>'navigation'});
    }
    
    print td({-class=>'navcell'},
	     a({-href=>"/music/music.cgi?action=browse&class=$type&$type=$_"},$_));
    $count++;
  }
  print end_table;
  print end_div;
}

# Display buttons for the bottom of the page
sub buttons {
  my $self = shift;
  my $playlists = Audio::DB::Util::Playlists->fetch_playlists(-type=>'by_user');
#  my $playlists = $self->fetch_playlists(-type=>'by_user');
  my $playlists = [];
  my (@ids,%labels);
  foreach (@$playlists) {
    push (@ids,$_->{playlist_id});
    $labels{$_->{playlist_id}} = $_->{playlist};
  }
  print start_table({-width=>'100%'});
  print TR({-class=>'colheaders'},td('action'),td('tracks'),td('Available Playlists'),td(''));
  print TR(
	   td(radio_group({-name=>'todo',
			   -values=>['stream','fetch','add to playlist'],
			   -linebreak=>1})),
	   #  td(popup_menu({-values=>['stream','fetch','to playlist...']})),
	   td(radio_group({-name=>'the_chosen',
			   -values=>[qw/All Selected/],
			   -linebreak=>1})),
	   td(popup_menu({-name=>'playlist',
			  -values=>\@ids,
			  -labels=>\%labels})),
	   td(submit()));

  print a({-href=>"javascript:OpenPlaylists(" . $self->{user_id} . ")"},
	  "Add to playlist...");

#  print a({-onclick=>"window.open('music.cgi?action=add_to_playlist&user
#-href=>"javascript:OpenPlaylists(" . $self->{user_id} . ")"},
#	  "Add to playlist...");
}


# NEED TO FIGURE OUT HOW TO LINK IN...
# THIS BELONGS IN THE MODULE
sub print_checkboxes {
  my ($self,$obj,$count) = @_;
  my $class = $obj->class;
  my $id_coderef = $class . '_id';
  print
    td({-align=>'center'},
       checkbox({-name  =>'checkbox' . $count,
		 -value =>$class . 's_' . $obj->$id_coderef,
		 -label => ''})
      );
  print td('stream');
}


#######################################
# Basic browsing and searching methods
#######################################
# This is for generic letter based browsing...
sub browse_by_letter {
  my ($self,$field) = @_;

  my $query  = "^" . url_param($field) . '.*';
  my $adaptor = $self->adaptor;

  # This creates a container object in which to store everything
  my $this = bless { class=>ucfirst $field . 'List'},"Audio::DB::DataTypes::" . ucfirst $field . 'List';
  my $sth = $adaptor->fetch_by_letter($query,$field);
  my $dbh = $self->dbh;

  # This should all probably be moved to dbi::mysql since it has the fetchrow query
  while (my $h = $sth->fetchrow_hashref) {
    # Create brief summary objects of each of the albums or artists that are
    # returned.
    if ($field eq 'album') {
      my $obj = Audio::DB::DataTypes::Album->new(-data=>$h);
      push (@{$this->{albums}},$obj);
    } else {
      my $obj = Audio::DB::DataTypes::Artist->new(-data=>$h);
      push (@{$this->{artists}},$obj);
    }
  }
  return $this;
}


# Browse specific wrappers around different parameters
sub browse_genre {
  my $self = shift;
  my $artist_id = url_param('artist_id');
  my $genre_id  = url_param('genre_id');
  my $adaptor = $self->adaptor;

  # Browse by an artist id....
  if ($artist_id) {
    return  (Audio::DB::DataTypes::Artist->new(-adaptor=>$adaptor,-id=>$artist_id));
    # Or a genre id...
  } elsif ($genre_id) {
    return (Audio::DB::DataTypes::Genre->new(-adaptor=>$adaptor,-id=>$genre_id));
  } else {
    return (Audio::DB::DataTypes::GenreList->new(-adaptor=>$adaptor));
  }
  return;
}

sub browse_artist {
  my $self = shift;
  my $artist    = url_param('artist');
  my $artist_id = url_param('artist_id');
  my $album_id  = url_param('album_id');
  my $adaptor = $self->adaptor;

  # 2004: THIS SHOULD BE FETCH ARTIST...
  if ($artist) {
    return ($self->browse_by_letter('artist'));
  }  elsif ($album_id) {
    return (Audio::DB::DataTypes::Album->new(-adaptor=>$adaptor,-id=>$album_id));
  } else {
    return (Audio::DB::DataTypes::Artist->new(-adaptor=>$adaptor,-id=>$artist_id));
  }
}



sub browse_album {
  my $self = shift;
  my $album     = url_param('album');
  my $album_id  = url_param('album_id');
  my $adaptor = $self->adaptor;

  my $results = [];
  if ($album) {
    return ($self->browse_by_letter('album'));
  }  elsif ($album_id) {
    return (Audio::DB::DataTypes::Album->new(-adaptor=>$adaptor,-id=>$album_id));
  } else { }

  ### EMPTY - SHOULD JUST RETURN THE NAVIGATION
  
  # This should just return the naviagation...
  # $results = $self->retrieve_artist();
  #  }
  return $results;
}


# NOT YET IMPLEMENTED
sub _fetch_song {
  my $self = shift;
  my $dbh = $self->dbh;
  
  my $sth = $dbh->prepare(qq{select * from songs,genres,artists,albums
			    where songs.song_id=? 
			    and songs.artist_id=artists.artist_id
			    and songs.genre_id=genres.genre_id
			    and songs.album_id=albums.album_id});
  $sth->execute(url_param('song_id'));
  my $h = $sth->fetchrow_hashref;
  return (Audio::DB::DataTypes::Song->new($h));
}




####################################
# Authentication and cookie control
####################################
# This is my simple-minded cookie-based authentication scheme
# Move into sql
#sub check_cookie {
#  my $self = shift;
#
#  # Fetch the cookie if there is one...
#  my %cookie = cookie(-name => 'musicdb');
#  my $user_id = $cookie{userid};
#
#  # If a cookie was present, let's make sure to reset it ...
#  if ($user_id) {
#    $self->build_cookie($user_id);
#    return;
#  } elsif (param('submit') eq 'Log In') {
#    $self->authenticate();
#  } else {
#    $self->{cookie} = 'NOT AUTHENTICATED';
#  }
#}
#
#sub build_cookie {
#  my ($self,$user_id) = @_;
#  # Store the user id in the object for
#  # building custom page elements
#  $self->{user_id}    = $user_id;
#
#  # Could easily store more information in the cookie, too...
#  my %vals = (userid => $user_id);
#  my $cookie = cookie(-name =>'musicdb',
#		      -value=>\%vals);
#  $self->{cookie} = $cookie;
#  return;
#}
#
#sub authenticate {
#  my $self     = shift;
#  my $password = param('password');
#  my $dbh = $self->dbh;
#  my $sth = $dbh->prepare(qq{select password,user_id from users where username=?});
#  $sth->execute(param('username'));
#  my ($pass,$user_id) = $sth->fetchrow_array;
#  if ($pass eq $password) {
#    $self->build_cookie($user_id);
#    return;
#  } else {
#    $self->{cookie} = 'BOGUS GUESS';
#  }
#}



1;


=pod

=head1 NAME

  Audio::DB::Web - Assists in web-based queries of an MP3 Database

=head1 SYNOPSIS
  
  use Audio::DB::Web;
  my $mp3->


=head1 DESCRIPTION

Audio::DB is a module for creating relational databases of MP3 files directly
from data stored in ID3 tags.  Once created, Audio::DB provides various
methods for creating reports and web pages of your collection. Although
it's nutritious and delicious on its own, Audio::DB was created for use
with Apache::Audio::DB, a subclass of Apache::MP3.  This module makes it 
easy to make your collection web-accessible, complete with browsing, 
searching, streaming, multiple users, playlists, ratings, and more!

=head1 REQUIRES

This module is designed to work with the data schema created
and loaded by B<Audio::DB>.  It's not going to do you mch good without it.

=head1 EXPORTS
    
No methods are exported.
    
=head1 CAVEATS

=head1 METHODS


=head2 fetch_user_playlists();

  Title    : fetch_user_playlists
  Usage    : $mp3->fetch_user_playlists();
  Function : fetches all playlists
  Returns  : A hash reference relating user playlist names to IDs
             suitable for building forms.
  Args     : -filled
  Status   : Public



Methods:
user management
  multiplaylists / user  (and option to share with others)
  
  user ratings (for songs and playlists)
  
browse by letter of alphabet, genre, album
Stats reporting


=head1 NAME

Apache::Audio::DB - Generate a database of your tunes complete with searchable interface and nifty statistical analyses!

=head1 SYNOPSIS

# httpd.conf or srm.conf
AddType audio/mpeg    mp3 MP3
  
  # httpd.conf or access.conf
  <Location /songs>
  SetHandler perl-script
  PerlHandler Apache::MP3::Sorted
  PerlSetVar  SortFields    Album,Title,-Duration
  PerlSetVar  Fields        Title,Artist,Album,Duration
  </Location>

=head1 TODO


Streaming code and links

BUILDING URLs from non-blessed items...need to handle this because
it will come up alot

DB.pm Use lincolns code for scanning files

Browse filesystem

Update DB scripts

HTML module of common formatting options
configuration page...
    limits to return
    option to download tarballs
    
Figure out how to track paths and such...
   Preserving this state is kinda hairy

CLEAN UP THE BUILD URL SUB
OPTIMIZE QUERIES AND OBJECT CONSTRUCTION
SEPEERATE OUT OBJECT CODE

Seperate out HTML formatting into a seperate module

Error checking and handling

Streaming code
Column Sorting
User management
Playlist integration
Playlist sharing
Multiple Playlists
Interface preferences


=head1 DESCRIPTION

Apache::Audio::DB subclasses Apache::MP3 to generate a relational database
of your music collection.  This allows browsing by various criteria that
are not available when simply browsing the filesystem.  For example, 
users my browse by genre, year, or era.  Apache::Audio::DB also provides
search capabilities.

=head1 CUSTOMIZING

This class adds several new Apache configuration variable.

Database specific variables:
----------------------------
  Value                Default
  PerlSetVar    DB_Name     database name        musicdb
  PerlSetVar    Create      boolean              no
  PerlSetVar    Host        database user name   localhost
  PerlSetVar    User        user name            
  PerlSetVar    Password    db password
  
=over 4

=item B<DB_Name> I<field>

This is the name of the database.  If not provided, musicdb will be used.

=item B<Create>

Examples:

  PerlSetVar SortFields  Album,Title    # sort ascending by album, then title
  PerlSetVar SortFields  +Artist,-Kbps  # sort ascending by artist, descending by kbps

When constructing a playlist from a recursive directory listing,
sorting will be B<global> across all directories.  If no sort order is
specified, then the module reverts to sorting by file and directory
name.  A good value for SortFields is to sort by Artist,Album and
track:

PerlSetVar SortFields Artist,Album,Track

Alternatively, you might want to sort by Description, which
effectively sorts by title, artist and album.

The following are valid fields:

Field        Description
  
  album	 The album
  artist       The artist
  bitrate      Streaming rate of song in kbps
  comment      The comment field
  description	 Description, as controlled by DescriptionFormat
  duration     Duration of the song in hour, minute, second format
  filename	 The physical name of the .mp3 file
  genre        The genre
  samplerate   Sample rate, in KHz
  seconds      Duration of the song in seconds
  title        The title of the song
  track	 The track number

Field names are case insensitive.

=back

=head1 METHODS

Apache::MP3::Sorted overrides the following methods:

sort_mp3s()  mp3_table_header()   mp3_list_bottom()

It adds one new method:

=over 4

=item $field = $mp3->sort_fields

Returns a list of the names of the fields to sort on by default.



#### UI ELEMENTS THAT HAVEN'T BEEN REWORKED YET
#sub amg_link {
#  my ($artist,$link_text) = @_;
  
#  # Encode $artist for searching: UC, replace \s with |, replace ' and ,
#  my $artist_encoded = uc $artist;
#  $artist_encoded =~ s/\s/|/g;
#  $artist_encoded =~ s/[,\'\-]//g;
#  my $base_url = 'http://allmusic.com/cg/x.dll?p=amg&optl=1&sql=1';
  
#  my $full_url = $base_url . $artist_encoded;
  
#  # Formulate the AMG URL
#  my $amg_link = '<a href="' . $base_url . $artist_encoded . '">' . 
#  $link_text . "</a>";
  
#  return($amg_link);
#}

#sub print_search_button {
#  print center(
#	       startform(-action=>$full_url),
#	       submit(-name=>'submit',
#			    -value=>'Search Again'),
#	       endform);
#  return;
#}

# Playlists.pm provides a variety of methods for dealing with playlists.
# This includes the basics (like adding and deleting songs from playlists),
# To actual streaming of recalled playlists,
# to retrieving all playlists from all users for display

# Flow
# 1. Authenticate (either through mod_auth or by reading cookie)
# 2. Grab the user id from the cookie
# 3. Use that to do any sort of deletes or inserts...

# Handles:
# Displaying a given users list of playlists
# Retrieval of a single playlist
# Let's them add a new playlist

# NEED TO STANDARDIZE THE NAVIGATION ELEMENTS
# Lists of playlists need
# stream fetch
# Each playlist needs 
# stream fetch for each song and stream fetch for whole playlist



package Audio::DB::Util::Playlists;

# $Id: Playlists.pm,v 1.2 2005/02/27 16:56:25 todd Exp $

use strict 'vars';

use CGI qw/:standard *table/;
use Audio::DB::Web;
use Audio::DB::Util::Rearrange;  # Ubiquitous rearrange...
use vars qw($VERSION @ISA);
@ISA = 'Audio::DB::Web';

my $MAIN = 'My Playlists';
my $EDIT = 'images/edit.gif';
my $DELE = 'images/edit.gif';

# Need to store a dbh handle here
# as well as the user ID...
sub new {
  my ($self,$dbh,$user_id) = @_;
  my $this = bless { dbh     => $dbh,
		     user_id => $user_id
		   },$self;
  $this->process_requests();
  return $this;
}


sub process_requests {
  my $self    = shift;
  my $coderef = url_param('playlist');

  # Some coderefs are actually NOT url_params, things
  # like adding songs to playlists, etc
  $coderef = param('todo') if param('todo');
  $coderef =~ s/\s/_/g;
  $self->$coderef;

  # Print out the appropriate title...
  # Better to do it here so that I can jump in later
  # and print forms on the fly without the intervening table
  # IN an ideal world, that is how it would work

  # Print out the various playlist options
  $self->display_options(1) unless ($coderef eq 'display_options');
  print end_div;
}

sub display_options {
  my ($self,$suppress) = @_;
  $self->print_navigation() unless ($suppress);
  print start_div({-class=>'configoptions'});
  print h4($self->build_nav_link(-class=>'playlist',-action=>'browse_user_playlists',
				 -text=>'Browse Your Playlists'));
  print h4($self->build_nav_link(-class=>'playlist',-action=>'browse_all_playlists',
				 -text=>'Browse All Playlists'));
  print h4($self->build_nav_link(-class=>'playlist',-action=>'create_new_playlist',
				 -text=>'Create New Playlist'));
  print h4($self->build_nav_link(-class=>'playlist',-action=>'delete_all_playlists',
				 -text=>'Delete All Of Your Playlists'));
}


sub create_new_playlist {
  my ($self,$suppress) = @_;
  my $user_id = $self->{user_id};
  if (param('submit')) {
    $self->print_navigation('Create A New Playlist (Results)');
    $self->add_entry(-table       => 'playlists',
		     -success_msg => 'The playlist ' . span({-class=>'name'},param('playlist'))
		     . ' has been successfully added.',
		     -user_id=>$user_id);
  } else {
    unless ($suppress) {
      $self->print_navigation($self->build_nav_link(-class=>'playlist',-action=>'create_new_playlist',
						    -text=>'Create New Playlist'));
    }
    print start_div({-class=>'actioncontent'});
    print "Use this form to add a new playlist.";
    Delete('playlist');
    print startform(),
      start_table(),
	TR(td('Playlist Name'),td(textfield({-name=>'playlist'}))),
	  TR(td('Description'),td(textfield({-name=>'description'}))),
	    TR(td('Publically viewable?'),td(popup_menu({-name=>'is_shared',-values=>[qw/yes no/]}))),
	      TR(td({-colspan=>2,-align=>'right'},
		    submit(-name=>'submit',-label=>'Add New Playlist'))),
		      end_table;
    # Fetch all the user playlists
    print end_div;
  }
}





# Currently, this just displays a flat listing of the playlist?
sub display_playlist {
  my ($self,$id) = @_;
  $id ||= url_param('id');
  my $tracks = $self->fetch_playlists(-type=>'filled',-id=>$id);
  # I need some blanket description of the playlist here

  # Also need all of my typical checkboxes...
  my @cols = qw/Select stream song artist album genre/;
  print div({-class=>'actionbyline'},"Browsing Playlist");
  print start_div({-class=>'actioncontent'});
  print  start_table(),TR(td(\@cols));
  
  my $count;
  my $total;
  foreach my $song (@$tracks) {
    # Build up some links for each item.
    # can't use the normal mechanism since the individual songs are not blessed.
    my $song_link   = $self->build_url('song',$song);
    my $album_link  = $self->build_url('album',$song);
    my $artist_link = $self->build_url('artist',$song);
    my $genre_link  = $self->build_url('genre',$song);
    
    $total++;
    $count = ($count eq 'one' ) ? 'two' : 'one';
    print start_TR({-class=>"shade$count"});
    #    $self->print_checkboxes($song,$total);
    my $track;
    
    # I should only print the artist column if this is a compilation CD
    print
      td($song_link),
	td($artist_link),
	  td($album_link),
	    td($song->{duration}),
	      td($song->{bitrate}),
		td($genre_link),
		  end_TR;
  }
# line 500
print end_table,end_div;
}



#######################################################
#  BROWSING PLAYLISTS
#######################################################
sub browse_all_playlists {
  my $self = shift;
  $self->print_navigation($self->build_nav_link(-class=>'playlist',
						-action=>'browse_all_playlists',
						-text=>'Browse All Playlists'));
  my $playlists = $self->fetch_playlists(-type=>'all');
  if ($playlists) {
    print div({-class=>'actionbyline'},"All User Playlists");
    print start_div({-class=>'actioncontent'});
    my @cols = (qw/Playlist Owner Description Created/);
    print  start_table(),TR(td(\@cols));
    foreach (@$playlists) {
      print TR(td($self->link_playlist($_->{playlist},$_->{playlist_id})),
	       td($_->{username} . "(" . $_->{first_name} . ' ' . $_->{last_name} . ")"),
	       td($_->{description}),
	       td($_->{created}));
    }
    print end_table,end_div;
  } else {
    print div({-class=>'actionbyline'},"There aren't any user-created playlists yet.",br,
	      $self->build_nav_link(-class=>'playlist',
				    -action=>'create_new_playlist',
				    -text=>'Create A New Paylist'));
  }
}

sub browse_user_playlists {
  my $self = shift;
  $self->print_navigation($self->build_nav_link(-class=>'playlist',
						-action=>'browse_user_playlists',
						-text=>'Browse My Playlists'));
  my $playlists = $self->fetch_playlists(-type=>'by_user');
  if ($playlists) {
    # Also need all of my typical checkboxes...
    my @cols = qw/Playlist Description Public edit delete/;
    print div({-class=>'actionbyline'},"These are your currently available playlists:");
    print start_div({-class=>'actioncontent'});
    print  start_table(),TR(td(\@cols));
    foreach (@$playlists) {
      print TR(
	       # What should this link really be?
	       td($self->link_playlist($_->{playlist},$_->{playlist_id})),
	       td($_->{description}),
	       td($_->{is_shared}),
	       td($self->build_edit_link('edit',$_->{playlist_id})),
	       td($self->build_edit_link('delete',$_->{playlist_id})),
	      );
    }
    print end_table,end_div;
  } else {
    print div({-class=>'actionbyline'},"You haven't created any playlists yet.",br,
	      $self->build_nav_link(-class=>'playlist',
				    -action=>'create_new_playlist',
				    -text=>'Create A New Paylist'));
  }
}


sub build_edit_link {
  my ($self,$type,$id) = @_;
  my $IMG;
  if ($type eq 'edit') {
    $IMG = $EDIT;
  } else {
    $IMG = $DELE;
  }

  my $url = url();
  return a({-href=>$url . '?playlist=' . $type . '_playlist&id=' . $id },
	   img({-src=>$IMG}));
}

#######################################################
#  EDITING PLAYLISTS
#######################################################
sub add_to_playlist {
  my $self = shift;
  my $dbh = $self->{dbh};

  # Which playlist are we trying to add to?
  my $playlist_id = param('playlist');

  # Now, fetch out the id's of everything that we are trying to add to the playlist
  # Have to iterate over the checkboxes to get them all.  Yuck.
  # There must be some way to shortcircuit though, yes?
  my @to_add;
  for (my $i=1;$i<=10000;$i++) {
    push (@to_add,param('checkbox' . $i));
  }

  # Can add several things:
  # 1. A list of songs...
  # 2. A list of albums...
  # 3. A list of artists...
  # 4. A list of genres...
  
  # Each checkbox is called class_id
  # Extract the class from the first element in the list
  my $class = ($to_add[0] =~ /(.*)_.*/) ? $1 : 'songs';
  
  # The easiest case - a bunch of songs.
  # Just add them all to the playlist table.
  my $count;
  if ($class eq 'songs') {
    foreach (@to_add) {
      my $id = ($_ =~ /.*_(.*)/) ? $1 : '';
      my $result = $self->insert_songs($playlist_id,$id);
      $count += $result;
    }
    # Now I have to fetch all of the songs
    # that are associated with a given album, artist, or genre...
  } else {
    my %queries = (albums  => 'album_id',
		   artists => 'artist_id',
		   genres  => 'genre_id');
    
    my $query = $queries{$class};
    my $sth = $dbh->prepare(qq{select song_id from songs where } . $query . qq{=?});
    foreach (@to_add) {
      my $id = ($_ =~ /.*_(.*)/) ? $1 : '';
      $sth->execute($id);
      while (my ($song_id) = $sth->fetchrow_array) {
	my $result = $self->insert_songs($playlist_id,$song_id);
        $count += $result;
      }
    }
  }
  
  # Now display a message and the number of tracks add ed to the playlist
  print "$count tracks were added to: ";
  $self->display_playlist($playlist_id);
}


sub insert_songs {
  my ($self,$playlist_id,$song_id) = @_;
  my $dbh = $self->{dbh};
  $dbh->do("insert into playlist_songs (playlist_id,song_id) VALUES ($playlist_id" 
			. ',' . $dbh->quote($song_id) . ')');
  my $result = abs $dbh->rows;
  return $result;
}




# MAYBE EDITS SHOULD JUST BE SUPERSEDED WITH A SINGLE CHECBOX ON EACH
# listing?
# THIS NEEDS TO BE FLESHED OUT...
# I will be editing a single playlist at a time...
### IT"S NOT DONE YET

# THIS WILL BE A LINK IN
sub edit_playlist {
  my $self = shift;
  $self->print_navigation($self->build_nav_link(-class=>'playlist',
						-action=>'edit_playlist',
						-text=>'Edit Playlists'));
  
  my $id     = url_param('id');
  my $tracks = $self->fetch_playlists(-type=>'filled',-id=>$id);

  my @cols = qw/select Song Artist Album Genre/;
  print div({-class=>'actionbyline'},
	    "Use this form to edit the tracks of the current playlists");
  print start_div({-class=>'actioncontent'});
  print startform(),
    start_table();
  print TR(td(\@cols));
  
  # First I need to print a header for the playlist, letting user edit the name
  # and shared properties.
#    print
#      hidden(-name=>'playlist_id',-value=>$h->{playlist_id});
#    print
#      TR(td(textfield({-name=>'playlist',-value=>$h->{playlist},-size=>15})),
##	 td(textfield({-name=>'description',-value=>$h->{description},-size=>15})),
#	 td(textfield({-name=>'email',-value=>$h->{created},-size=>20})),
#	 td(popup_menu({-name=>'is_shared',-values=>[qw/yes no/]})));
#
#  $sth->execute();
#  while (my $h = $sth->fetchrow_hashref) {
#
#  }
  print end_table;
  print submit(-name=>'submit',-label=>'Update Users');
  print end_div;
}


sub delete_playlist {

}


sub delete_all_playlists {

}



sub playlist_popup {
  my $self = shift;
  # Flow
  # 1. Create the popup window
  # 2. Fetch user playlists
  # 3. Display form
 
  # Processing...
  # Should songs be added to new playlist?
  #       Creat playlist, then add songs.
  # Should songs be added to existing playlist?
  # Popupmen presents: view playlist or return...

  # Example code for creating a javapopup window
  # <script language="javascript" type="text/javascript">
  # function OpenComments (c) {
  #    window.open('<$MTCGIPath$>mt-comments.cgi?' +
  #                    'entry_id=' + c,
  #                    'comments',
  #                    'width=480,height=480,scrollbars=yes,status=yes');
  #}
  #</script>
  #
  #}
}


#######################################################
#  SUPPORT: Fetching, streaming, linking, navigating
#######################################################

# Fetch all the current playlists associated with
# this user and return 
# This could be generalized to get lists of all playlists
# from all users
# Or perhaps that should just be a seperate sub

# Could also be modified to return a filled list
# This might actually be usefull, because then I can build the page
# from that

# Should this be a factory churning out Playlistlist objects?

sub fetch_playlists {
  my ($self,@p) = @_;
  my ($type,$id) = rearrange([qw/TYPE ID/],@p);

  # Cases:
  # 1. fetch playlists for a specific user, 
  # 2. Browse all playlists
  # 3. fetch an individual playlist
  
  # UI could present a popupmenu for each user
  # Or alternatively, could expand them all
  my $user_id = $self->{user_id};
  my $dbh = $self->dbh;

  # This is the flat query that simply returns all the playlists
  # but does not actually list the song ids
  my %queries = ( by_user => qq{select * from playlists where user_id=?},
		  all      => qq{select * from playlists,users where
				 playlists.user_id=users.user_id
				 ORDER BY last_name},
		  expanded => qq{select *,count(song_id) from playlists,playlist_songs 
				 where
				 playlists.user_id=? 
				 and playlists.playlist_id=playlist_songs.playlist_id
				 GROUP BY playlist_id},
		  filled => qq{select * from playlists,playlist_songs,songs,artists,albums,genres
			       where
			       playlists.playlist_id=? 
			       and playlists.playlist_id=playlist_songs.playlist_id
			       and playlist_songs.song_id=songs.song_id
			       and songs.artist_id=artists.artist_id
			       and songs.genre_id=genres.genre_id
			       and songs.album_id=albums.album_id});
  my $results = [];
  my $sth = $dbh->prepare($queries{$type});
  if ($type eq 'by_user') {
    $sth->execute($user_id);
  } elsif ($type eq 'filled') {
    # Argh! What should this be and where should it come from?
    $sth->execute($id);
  } elsif ($type eq 'all') {
    $sth->execute();
  } else {
    $sth->execute();
  }
  
  my $c;
  while (my $h = $sth->fetchrow_hashref) {
    push (@$results,$h);
    $c++;
  }
  return '' if $c < 1;
  return $results;
}


# This will be a generic link in, and not for streaming
sub link_playlist {
  my ($self,$playlist,$id) = @_;
  my $url = url();
  return a({-href=>$url . '?playlist=' . 'display_playlist&id=' . $id },$playlist);
}

sub stream_link {

}


# THIS CONTROLS NAVIGATIONAL FORMATTING
sub print_navigation { 
  my ($self,@fields) = @_;
  print start_div({-class=>'actiontitle'}),
    $self->build_nav_link(-class=>'playlist',-action=>'display_options',
		      -text=>$MAIN);
  print ' / ' if (@fields);
  print join (' / ',@fields);
  print end_div;
}




1;

=pod
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

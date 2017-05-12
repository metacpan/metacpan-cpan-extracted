# SystemConfig.pm handles administration and configuration requests including
# Adding, deleting, and editing users.
# Deleting all playlists
# Setting up overall formatting issues

# This has a *lot* of hard-coded formatting
# Would instead prefer to return each of these
# letting users format them at will

package Audio::DB::Util::SystemConfig;

# $Id: SystemConfig.pm,v 1.2 2005/02/27 16:56:25 todd Exp $

use strict 'vars';
use vars qw($VERSION @ISA);
use lib '/Users/todd/projects_personal';
use CGI qw/:standard *table *TR *td *div/;
use Audio::DB::Web;
@ISA = 'Audio::DB::Web';

my %links = (
	     add_user             => 'display_user_options',
	     edit_users           => 'display_user_options',
	     delete_user          => 'display_user_options',
	     delete_all_users     => 'display_user_options',
	     user_summary         => 'display_user_options',
	     delete_all_playlists => 'display_playlist_options');



my $MAIN = 'System Configuration';


# Check to see if the current user has permissions to do whatever they are trying to do
sub check_permissions {

}

# Need to store a dbh handle here
sub new {
  my ($self,$dbh) = @_;
  my $this = bless { dbh => $dbh },$self;
  $this->process_requests();
  return $this;
}


sub process_requests {
  my $self = shift;
  my $coderef = url_param('admin');
  $self->$coderef();

  # Print out the original option list for the subcategory
  # I am working within
  if (my $footer_ref = $links{$coderef}) {  $self->$footer_ref(1); }
  print end_div;
}

sub display_options {
  my $self = shift;
  $self->print_navigation();
  print start_div({-class=>'configoptions'});
  print h4($self->build_nav_link(-class=>'admin',-action=>'display_user_options',
			     -text=>'User Management'));
  print h4($self->build_nav_link(-class=>'admin',-action=>'display_playlist_options',
			     -text=>'Global Playlist Management'));
}



##################################################
# USER MANAGEMENT SUBROUTINES
##################################################
sub display_user_options {
  my ($self,$suppress) = @_;
  
  # I don't want to doubly print the navigation...
  unless ($suppress) {
    $self->print_navigation($self->build_nav_link(-class=>'admin',-action=>'display_user_options',
						  -text=>'User Configuration'));
  }
  
  print start_div({-class=>'configoptions'});
  print h4($self->build_nav_link(-class=>'admin',-action=>'add_user',-text=>'Add A New User'));
  print h4($self->build_nav_link(-class=>'admin',-action=>'edit_users',-text=>'Edit Users'));
  print h4($self->build_nav_link(-class=>'admin',-action=>'delete_user',-text=>'Delete A User')
	   . ' | ' .
	   $self->build_nav_link(-class=>'admin',-action=>'delete_all_users',-text=>'Delete All Users'));
  print h4($self->build_nav_link(-class=>'admin',-action=>'user_summary',-text=>'View All Users'));
}


sub display_playlist_options {
  my ($self,$suppress) = @_;
  
  # I don't want to doubly print the navigation...
  unless ($suppress) {
    $self->print_navigation($self->build_nav_link(-class=>'admin',-action=>'display_playlist_options',
						  -text=>'Global Playlist Options'));
  }
  
  print start_div({-class=>'configoptions'});
  print h4($self->build_nav_link(-class=>'admin',-action=>'delete_all_playlists',
			     -text=>'Delete All Playlists'));
}

sub add_user {
  my $self = shift;
  if (param('submit')) {
    $self->print_navigation($self->build_nav_link(-class=>'admin',-action=>'display_user_options',
						  -text=>'User Configuration'),
			    'Add A New User (Results)');
    $self->add_entry(-table       => 'users',
		     -success_msg => span({-class=>'name'},param('first_name') 
					  . ' ' . param('last_name')) . 
		     ' has been succesfully added to the system with the following parameters:',
		     -detailed => 'true');
  } else {
    $self->print_navigation($self->build_nav_link(-class=>'admin',-action=>'display_user_options',
						  -text=>'User Configuration'),
			    $self->build_nav_link(-class=>'admin',-action=>'add_user',
						  -text=>'Add A New User'));
    $self->print_add_form();
  }
}


sub edit_users {
  my $self = shift;
  if (param('submit')) {
    $self->print_navigation($self->build_nav_link(-class=>'admin',-action=>'display_user_options',
						  -text=>'User Configuration'),
			    'Edit Users (Results)');
    $self->process_edit_form();
  } else {
    $self->print_navigation($self->build_nav_link(-class=>'admin',-action=>'display_user_options',
						  -text=>'User Configuration'),
			    $self->build_nav_link(-class=>'admin',-action=>'edit_users',
						  -text=>'Edit Users'));
    $self->print_edit_form();
  }
}

sub print_add_form {
  my $self = shift;
  # Print out the form
  
  print div({-class=>'actionbyline'},"Use this form to add new users to the Music Repository");    
  print start_div({-class=>'actioncontent'});
  print startform(),
    start_table(),
      TR(td('first name'),td(textfield({-name=>'first_name'}))),
	TR(td('last name'),td(textfield({-name=>'last_name'}))),
	  TR(td('email'),td(textfield({-name=>'email'}))),
	    TR(td('username'),td(textfield({-name=>'username'}))),
	      TR(td('password'),td(textfield({-name=>'password'}))),
		TR(td('priviledges'),
		   td(popup_menu({-name=>'privs',-values=>[qw/user admin overlord/]}))),
		  TR(td({-colspan=>2,-align=>'right'},
			submit(-name=>'submit',-label=>'Add New User'))),
			  end_form,
			    end_table;
  print end_div;
}

sub print_edit_form {
  my $self = shift;
  my @cols = qw/First Last Email Username Password Priviledges/;
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare(qq{select * from users});
  print div({-class=>'actionbyline'},
	    "Use this form to edit the information of all users simultaneously.");
  print start_div({-class=>'actioncontent'});
  print startform(),
    start_table();
  print TR(td(\@cols));
  $sth->execute();
  while (my $h = $sth->fetchrow_hashref) {
    print 
      hidden(-name=>'user_id',-value=>$h->{user_id});
    print
      TR(td(textfield({-name=>'first_name',-value=>$h->{first_name},-size=>15})),
	 td(textfield({-name=>'last_name',-value=>$h->{last_name},-size=>15})),
	 td(textfield({-name=>'email',-value=>$h->{email},-size=>20})),
	 td(textfield({-name=>'username',-value=>$h->{username},-size=>10})),
	 td(textfield({-name=>'password',-value=>$h->{password},-size=>10})),
	 td(popup_menu({-name=>'privs',-values=>[qw/user admin overlord/],
			-default=>$h->{privs}})));
  }
  print end_table;
  print submit(-name=>'submit',-label=>'Update Users');
  print end_div;
}


sub process_edit_form {
  my $self = shift;
  my $dbh = $self->{dbh};
  # iterate over each param...
  my @fields = qw/first_name last_name email username password privs/; 
  my @params = param();
  my $params = { id         => [ param('user_id') ],
		 first_name => [ param('first_name') ],
		 last_name  => [ param('last_name') ],
		 email      => [ param('email') ],
		 username   => [ param('username') ],
		 password   => [ param('password') ],
		 privs      => [ param('privs') ]  };
  
  # Yuck, there has to be a better way
  my $count = 0;
  my $result;
  foreach my $id (@{$params->{id}}) {
    my @vals;
    foreach (@fields) {
      push (@vals,$_ . "=" . $dbh->quote($params->{$_}[$count]));
    }

    $result = $dbh->do("update users set "
			  . join(",",@vals)
			  . " where user_id=$id");
    $count++;
  } 
  # This is kind of bogus - only looks at the last record updated.
  if ($result) {
    print div({-class=>'success'},"The users have been succesfully updated.");
  } else {
    $self->print_sql_error($dbh->errstr);
  }
}


sub user_summary {
  my $self = shift;
  $self->print_navigation($self->build_nav_link(-class=>'admin',-action=>'display_user_options',
						-text=>'User Configuration'),
			  $self->build_nav_link(-class=>'admin',-action=>'user_summary',
						-text=>'View All Users'));
  my $dbh = $self->{dbh};
  my $sth = $dbh->prepare(qq{select * from users ORDER BY last_name});
  $sth->execute();
  
  my @cols = ('First','Last','Email','Username','Status','Joined','Last Login','Songs Played');
  my @keys = ('first_name','last_name','email','username','privs','joined','last_access','songs_played');
  
  my $rows = [];
  while (my $h = $sth->fetchrow_hashref) {
    my @row;
    foreach (@keys) {
      push (@row,$h->{$_});
    }
    push (@$rows,[ @row ]);
  }
  if (@$rows) {
    print div({-class=>'actionbyline'},"Summary Information For All Users");
    print start_div({-class=>'actioncontent'});
    print start_table();
    print TR(td(\@cols));
    foreach (@$rows) {
      print TR(td(\@$_));
    }
    print end_table;
    print end_div;
  } else {
    print div({-class=>'warning'},"There are no users currently in the database");
  }
}


# First parameter is for establishing the navigation
sub delete_all_users {
  my $self = shift;
  $self->delete_all('User Configuration','users');
}

# Generalized delete all

# THIS IS KIND OF SILLY, AND MOSTLY JUST USED FOR DEBUGGING.
# Since ALL PLAYLISTS ARE ATACHED TO USERS
# I MUST NECESSARILY EMPTY OUT THE PLAYLISTS AND PLAYLIST_SONGS TABLES AS WELL
sub delete_all {
  my ($self,$text,$table) = @_;
  my $param = url_param('admin');
  my $action = $links{$param};
  if (param('delete')) {
    $self->print_navigation($self->build_nav_link(-class=>'admin',-action=>$action,-text=>$text),
			    'Delete All ' . uc $table . ' (Results)');
    my $dbh = $self->{dbh};
    my $result = $dbh->do(qq{delete from } . $table);
    # If I am deleting playlists, then I also need to empty out the songs table
    if ($table eq 'playlists') {
      my $result = $dbh->do(qq{delete from playlist_songs});
    }
    
    if ($table eq 'users') {
      my $result = $dbh->do(qq{delete from playlist_songs});
      my $result = $dbh->do(qq{delete from playlists});
    }
    
    if ($result) {
      print div({-class=>'success'},"All " . $table . " were deleted from the database.");
    } else {
      $self->print_sql_error($dbh->errstr);
    }
  } elsif (param('submit') eq 'Cancel') {
    $self->print_navigation(
			    $self->build_nav_link(-class=>'admin',-action=>$action,-text=>$text),
			    'Delete All ' . uc $table . ' (Cancelled)');
    print div({-class=>'success'},'The deletion was cancelled; no ' . $table . ' were deleted.');
  } else {
    $self->print_navigation(
			    $self->build_nav_link(-class=>'admin',-action=>$action,-text=>$text),
			    'Delete All ' . uc $table . ' (Confirmation)');
    print start_div({-class=>'warning'}),"You are about to delete ALL " . $table . 
      " from the database.";
    print start_form;
    print
      submit({-label=>'Delete All ' . uc $table,-name=>'delete'}),
	submit(-label=>'Cancel',-name=>'submit');
    print end_form,end_div;
  }
}



##################################################
# GLOBAL PLAYLIST MANAGEMENT SUBROUTINES
##################################################
sub delete_all_playlists {
  my $self = shift;
  $self->delete_all('Global Playlist Options','playlists');
}



##################################################
# USER INTERFACE CONFIGURATION SUBROUTINES
##################################################
# THIS CONTROLS NAVIGATIONAL FORMATTING
sub print_navigation { 
  my ($self,@fields) = @_;
  print start_div({-class=>'actiontitle'}),
    $self->build_nav_link(-class=>'admin',-action=>'display_options',
			  -text=>$MAIN);
  print ' / ' if (@fields);
  print join (' / ',@fields);
  print end_div;
}



sub print_sql_err {
  my $err;
  print span({-class=>'error'},$err);
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

#sub print_search_button {
#  print center(
#	       startform(-action=>$full_url),
#	       submit(-name=>'submit',
#			    -value=>'Search Again'),
#	       endform);
#  return;
#}

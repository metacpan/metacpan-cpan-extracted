# SongStats.pm provides methods that allow individual users to rate songs.
# It also does things like calculate the average rating for a song,
# as well as handling the incrementing of playcounts.

package Audio::DB::Util::SongStats;
$Id: Ratings.pm,v 1.2 2005/02/27 16:56:25 todd Exp $

use strict 'vars';
use lib '/Users/todd/projects_personal';
use Audio::DB::Util::Rearrange;  # Ubiquitous rearrange...
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA       = 'Exporter';
@EXPORT_OK = qw(add_to_playlist delete_from_playlist fetch_playlists);

sub add_user {
  my ($self,@p) = @_;
  my ($username,$login,$password,$privileges) = rearrange([qw/NAME USER PASS PRIVS/],@p);
  
  
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

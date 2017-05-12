package Audio::DB::Query;

# $Id: Query.pm,v 1.2 2005/02/27 16:56:25 todd Exp $

use strict 'vars';
use vars qw(@ISA $VERSION);
#use Apache::Constants qw(:common REDIRECT HTTP_NO_CONTENT);
#use CGI qw/:standard *table *div *TR/;
#use CGI::Cookie;
use DBI;

use Audio::DB::Factory;
use Audio::DB::Util::Rearrange;
use Audio::DB::Util::SystemConfig;
use Audio::DB::Util::Playlists;

use Audio::DB::DataTypes::Artist;
use Audio::DB::DataTypes::Album;
use Audio::DB::DataTypes::Genre;
#use Audio::DB::DataTypes::ArtistList;
#use Audio::DB::DataTypes::AlbumList;
#use Audio::DB::DataTypes::SongList;

@ISA = qw/Audio::DB::Util::DataAccess Audio::DB::Factory/;

=pod

=head1 NAME

Audio::DB::Query - query methods of a Audio::DB database

=head1 SYNOPSIS

Audio::DB::Query objects are used internally by Audio::DB::Reports and
Audio::DB::Web.  You will not normally interact with Audio::DB::Query
objects.  The documentation contained here is listed for completeness
as well as for those looking to extend the functionality of Audio::DB.

=head1 METHODS

=over 4

=cut

=pod

=item $report->fetch_class(@options);

Provided with a table name, fetch_class returns an array reference of
appropriate objects. For example, passing the -class=>'artists' option
results in an array reference of Audio::DB::DataTypes::Artist objects.

 Options:

Some classes accept additional parameters.

 Class: albums

 TODO: COMPLETE
   By default, album objects will not be populated with songs. To retreive populated Album objects, try using ...

   If provided, Album objects will be populated with Song
   objects. These can be accessed by calling the songs() method on
   each album object.

   @albums = $music->fetch_class(-class=>'artist');
   foreach my $album_obj (@albums) {
     print $album_obj->album,"\n";
     print join("\n",map {$_->title} $album_obj->songs);
   }

   If not provided, summaries that require touching each song (ie to
   see if it is a compilation album) will still be created, but the
   individual songs will not be returned.  This can be useful ina
   situation requiring greater speed and less memory consumption.

=cut

sub fetch_class {
  my ($self,@p) = @_;
  my ($class) = rearrange([qw/CLASS/],@p);
  my $adaptor = $self->adaptor;
  my $sth = $adaptor->generic_queries('fetch_class',$class);
  $sth->execute();
  my @temp;
  while (my $h = $sth->fetchrow_hashref) {
    # Create objects of the appropriate type
    my $obj = Audio::DB::Factory->new(-data =>$h,-class=>$class);
    push (@temp,$obj);
  }
  return \@temp;
}



####################################
#   Simple counts
#   eg: no of artists, albums, songs
#####################################

=pod

=head1 count()

 Usage: count('type');

     Where type is one of artists, albums, songs, genres
 Status: internal

Generate a simple count of the number of $type entries in
the database

=cut

sub count {
  my ($self,$table) = @_;
  my $adaptor = $self->adaptor;
  my $sth = $adaptor->generic_queries('simple_count',$table);
  $sth->execute();
  return ($sth->fetchrow_array)
}


sub dbh          { shift->adaptor->{dbh}; }
sub adaptor      { shift->{adaptor};      }


####################################
#   ARTIST QUERIES
####################################
# Fetch all of the songs for all artists
# If the fill option is provided, songs and genres will also be populated
# THIS COULD PROBABLY BE OPTIMIZED WITH A SINGLE QUERY INSTEAD OF 3
# ON THE OTHER HAND, THIS GIVES ME SEPERATE OBJECTS FOR EACH

# THIS IS A PAN METHOD THAT INVOKES fetch()

sub fetch_artist_with_albums {
  my ($self,@p) = @_;
  my ($query,$perspective,$fill,@others) = rearrange([qw/QUERY PERSPECTIVE FILL/],@p);
  my $adaptor = $self->adaptor;
  my $artists = $self->fetch_class(-query=>$query,-perspective=>$perspective);

  my $sth = $adaptor->album_queries('by_artist_id');
  foreach my $artist (@$artists) {
    $sth->execute($artist->artist_id);
    while (my $h = $sth->fetchrow_hashref) {
      my $obj = Audio::DB::Factory->new(-data=>$h,-class=>'album');
      $artist->add_album($obj);
    }
    
    # Filling the object. Group songs with albums
    if ($fill) {
      my $sth = $adaptor->song_queries('by_album_id');
      foreach my $album ($artist->albums) {
	$sth->execute($album->album_id);
	while (my $h = $sth->fetchrow_hashref) {
	  my $obj = Audio::DB::Factory->new(-data=>$h,-class=>'song');
	  $album->add_song($obj);
	}
      }
      
      # Now populate with genres
      my $sth = $adaptor->genre_queres('by_artist_id');
      $sth->execute($artist->artist_id);
      while (my $h = $sth->fetchrow_hashref) {
	my $obj = Audio::DB::Factory->new(-data=>$h,-class=>'genre');
	$artist->add_genre($obj);
      }
    }
  }
  return $artists;
}





####################################
#   ALBUM QUERIES
####################################
# WRITE SOME PAN METHODS LIKE
# fetch_album_with_songs




####################################
#   SONG QUERIES
####################################


####################################
#   GENRE QUERIES
####################################

# This is a generic method for fetching artists, albums, songs, or genres
# Options
# -class the primary class of the object to return
#    one of artist, album, song, or genre

# -perspective How to execute the fetch
#     This can be one of by_album_id
#                        by_album
#                        by_artist_id
#                        by_artist
# -query an internal ID or text-based query to retrieve
#
# For example
# fetch(-class=>'album',-query=>'Rolling Stones',-perspective=>'artist');
# Will fetch all albums for the Rolling Stones

# I SHOULD ALSO BE ABLE TO CALL THIS WITH AN OBJECT
# $artist->fetch(-class=>'album');
# (This would fetch and store all albums for the given artist
# That would be cool

sub fetch {
  my ($self,@p) = @_;
  my ($class,$query,$perspective,@others) = rearrange([qw/CLASS QUERY PERSPECTIVE/],@p);
  my $adaptor = $self->adaptor;

  my $coderef = $class . '_queries';
  my $sth;

  # (One of by_artist, by_album, by_song, by_genre);  
  # (One of by_artist_id, by_album_id, by_song_id, by_genre_id);
  $sth = $adaptor->$coderef($perspective);

  if ($query) {
    $sth->execute($query);
  } else {
    $sth->execute();
  }
  my @retain;
  while (my $h = $sth->fetchrow_hashref) {
    my $obj = Audio::DB::Factory->new(-data=>$h,-class=>$class);
    push @retain,$obj;
  }

  # TO DO: 

  # Return either a list object containing all items fetched
  # (list item should have a class key so I can easily find out how to
  # display it)

  # return the primary object if only one is fetched and user has
  # requested scalar

  # If we recovered more than a single object,
  # create a new container object. This lets me contextually
  # display items
  #if (@retain > 1) {
  #  my $list_obj = Audio::DB::Factory->new(-class=>$class . 'List');
  #  @{$list_obj->{(lc $class) . 's'}} = @retain;
  #  return $list_obj;
  #}
  #return (wantarray ? @retain : \@retain);
  return \@retain;
}

1;


package Buzznet::API;

use strict; use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Buzznet::API ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

#require XSLoader;
#XSLoader::load('Buzznet::API', $VERSION);

# Preloaded methods go here.
require RPC::XML;
require RPC::XML::Client;
require MIME::Base64;
use Buzznet::Entry;
use Buzznet::Comment;
use Buzznet::Profile;
use Buzznet::Gallery;


# Method constants
use constant NEWPOST 		=> "buzznet.newPost";
use constant EDITPOST 		=> "buzznet.editPost";
use constant REMOVEPOST 	=> "buzznet.removePost";
use constant GETENTRY 		=> "buzznet.getEntry";
use constant GETCOMMENTS 	=> "buzznet.getComments";
use constant ADDCOMMENT 	=> "buzznet.addComment";
use constant REMOVECOMMENT	=> "buzznet.removeComment";
use constant GETRECENTCOMMENTS 	=> "buzznet.getRecentComments";
use constant ADDBUZZWORDS 	=> "buzznet.addBuzzwords";
use constant REMOVEBUZZWORDS 	=> "buzznet.removeBuzzwords";
use constant UPDATEPROFILE	=> "buzznet.updateProfile";
use constant ADDFRIEND 		=> "buzznet.addFriend";
use constant REMOVEFRIEND 	=> "buzznet.removeFriend";
use constant ADDGALLERY 	=> "buzznet.addGallery";
use constant EDITGALLERY 	=> "buzznet.editGallery";
use constant REMOVEGALLERY 	=> "buzznet.removeGallery";
use constant ADDBOOKMARK 	=> "buzznet.addBookmark";
use constant REMOVEBOOKMARK 	=> "buzznet.removeBookmark";
use constant GETBOOKMARKS 	=> "buzznet.getBookmarks";
use constant GETMYFRIENDS 	=> "buzznet.getMyFriends";
use constant GETFRIENDS 	=> "buzznet.getFriends";
use constant GETFRIENDSRECENT 	=> "buzznet.getFriendsRecent";
use constant GETMOSTPOPULAR 	=> "buzznet.getMostPopular";
use constant GETTODAYSBIRTHDAYS => "buzznet.getTodaysBirthdays";
use constant GETONLINENOW 	=> "buzznet.getOnlineNow";
use constant GETRECENTPOSTS 	=> "buzznet.getRecentPosts";
use constant GETFEATUREDUSERS 	=> "buzznet.getFeaturedUsers";
use constant GETBUZZWORD 	=> "buzznet.getBuzzwords";
use constant BROWSEBUZZWORDS 	=> "buzznet.browseBuzzwords";
use constant GETGALLERY 	=> "buzznet.getGallery";
use constant GETSUBGALLERIES 	=> "buzznet.getSubGalleries";

sub new 
{
  my ($package,@refs) = @_;
  my $inst = {@refs};
  $inst->{"error"} = undef;
  return bless($inst,$package);
}

sub url
{
  my $self = shift;
  my $url = "http://www.buzznet.com/interface/xmlrpc/?key=" . $self->{"key"};
  return $url;
}

sub getXMLRPC
{
  my $self = shift;
  my $cli = RPC::XML::Client->new($self->url);
  $cli->credentials("Buzznet",$self->{"username"},$self->{"password"});
  my $request = $cli->request;
  return $cli;
}

sub sendRequest
{
  my $self = shift;

  my $request = RPC::XML::request->new(@_);

  my $client = $self->getXMLRPC;
  
  my $response = $client->send_request($request);

  if(ref($response))
  {
    if(!$response->value)
    {
      $self->{"error"} = "Error response from server";
    }
    return $response->value;
  }
  else
  {
    $self->{"error"} = $response;
 
    # error condition
    return 0;
  }
}

sub error
{
  my $self = shift;
  return $self->{"error"};
}

sub newPost 
{
  my $self = shift;
  my ($filename, $caption, $body, $category) = @_;
  
  my $encoded_file = "";

  eval
  {
    open(FILE,$filename) || die "Could not open $filename: $!\n";
    while(read(FILE,my $buf,60*57))
    {
      $encoded_file .= MIME::Base64::encode_base64($buf);
    }
    
  };

  if($@)
  {
    $self->{"error"} = $@;
    
    # error condition
    return 0;
  }

  return $self->sendRequest(NEWPOST,
                            RPC::XML::string->new($encoded_file),
                            RPC::XML::string->new($caption),
                            RPC::XML::string->new($body),
                            RPC::XML::string->new($category));

}

sub editPost
{
  my $self = shift;
  my ($entryId, $filename, $caption, $body, $category) = @_;
  
  my $encoded_file = "";

  eval
  {
    open(FILE,$filename) || die "Could not open $filename: $!\n";
    while(read(FILE,my $buf,60*57))
    {
      $encoded_file .= MIME::Base64::encode_base64($buf);
    }
    
  };

  if($@)
  {
    $self->{"error"} = $@;
    
    # error condition
    return 0;
  }

  return $self->sendRequest(EDITPOST,
                            RPC::XML::string->new($entryId),
                            RPC::XML::string->new($encoded_file),
                            RPC::XML::string->new($caption),
                            RPC::XML::string->new($body));
}

sub removePost
{
  my $self = shift;
  my $entryId = shift;

  return $self->sendRequest(REMOVEPOST,RPC::XML::string->new($entryId));
}

sub getEntry
{
  my $self = shift;
  my ($entryId, $type) = @_;

  print "ENTRY: $entryId\n";
  print "TYPE: $type\n";
  my $rawentry = $self->sendRequest(GETENTRY,
                                    RPC::XML::string->new($entryId),
                                    RPC::XML::string->new($type));

  if($rawentry)
  {
    return Buzznet::Entry->new(%{$rawentry});
  }
  else
  {
    return $rawentry;
  }
}

sub addGallery
{
  my $self = shift;
  my ($name, $title, $description, $keyword, $password) = @_;

  return $self->sendRequest(ADDGALLERY,
			    RPC::XML::string->new($name), 
			    RPC::XML::string->new($title), 
			    RPC::XML::string->new($description), 
			    RPC::XML::string->new($keyword), 
			    RPC::XML::string->new($password));
}

sub editGallery
{
  my $self = shift;
  my ($name, $title, $description, $keyword, $password) = @_;

  return $self->sendRequest(EDITGALLERY,
			    RPC::XML::string->new($name), 
			    RPC::XML::string->new($title), 
			    RPC::XML::string->new($description), 
			    RPC::XML::string->new($keyword), 
			    RPC::XML::string->new($password));
}

sub removeGallery
{
  my $self = shift;
  my $name = shift;

  return $self->sendRequest(REMOVEGALLERY,RPC::XML::string->new($name));
}

sub getSubGalleries
{
  my $self = shift;
  my $username = shift;

  my $rawgalleries = $self->sendRequest(GETSUBGALLERIES,
                                        RPC::XML::string->new($username));

  my @galleries = ();
  if($rawgalleries)
  {
    foreach my $gallery (@{$rawgalleries})
    {
      my %hash = %{$gallery};
      my $buzznetGallery = Buzznet::Gallery->new(%hash);
      push(@galleries,$buzznetGallery);
    }
  }

  return @galleries;
}

sub getGallery
{
  my $self = shift;
  my ($blogname, $mode, $user_cat, $current_page, $pagesize) = @_;

  my $rawentries = $self->sendRequest(GETGALLERY, 
                                      RPC::XML::string->new($blogname),
                                      RPC::XML::string->new($mode),
                                      RPC::XML::string->new($user_cat),
                                      RPC::XML::int->new($current_page),
                                      RPC::XML::int->new($pagesize));


  my @entries = ();
  if($rawentries)
  {
    foreach my $entry (@{$rawentries})
    {
      my %hash = %{$entry};
      my $buzznetEntry = Buzznet::Entry->new(%hash);
      push(@entries,$buzznetEntry);
    }
  }

  return @entries;
    
}

sub getRecentPosts
{
  my $self = shift;
  my $type = shift;

  my $rawentries = $self->sendRequest(GETRECENTPOSTS, 
                                      RPC::XML::string->new($type));


  my @entries = ();
  if($rawentries)
  {
    foreach my $entry (@{$rawentries})
    {
      my %hash = %{$entry};
      my $buzznetEntry = Buzznet::Entry->new(%hash);
      push(@entries,$buzznetEntry);
    }
  }

  return @entries;
}

sub getComments
{
  my $self = shift;
  my ($entryId, $type) = @_;

  my $rawcomments = $self->sendRequest(GETCOMMENTS, 
                                       RPC::XML::string->new($entryId),
                                       RPC::XML::string->new($type));


  my @comments = ();
  if($rawcomments)
  {
    foreach my $comment (@{$rawcomments})
    {
      my %hash = %{$comment};
      my $buzznetComment = Buzznet::Comment->new(%hash);
      push(@comments,$buzznetComment);
    }
  }

  return @comments;
  
}

sub addComment
{
  my $self = shift;
  my ($entryId, $comment, $type) = @_;

  return $self->sendRequest(ADDCOMMENT,
			    RPC::XML::string->new($entryId), 
			    RPC::XML::string->new($comment), 
			    RPC::XML::string->new($type)); 
}

sub removeComment
{
  my $self = shift;
  my $commentId = shift;
  
  return $self->sendRequest(REMOVECOMMENT,
                            RPC::XML::string->new($commentId));
  
}

sub getRecentComments
{
  my $self = shift;
  my $username = shift;

  my $rawcomments = $self->sendRequest(GETRECENTCOMMENTS, 
                                       RPC::XML::string->new($username));


  my @comments = ();
  if($rawcomments)
  {
    foreach my $comment (@{$rawcomments})
    {
      my %hash = %{$comment};
      my $buzznetComment = Buzznet::Comment->new(%hash);
      push(@comments,$buzznetComment);
    }
  }

  return @comments;
}

sub addBuzzwords
{
  my $self = shift;
  my ($entryId, $buzzwords, $type) = @_;

  return $self->sendRequest(ADDBUZZWORDS,
			    RPC::XML::string->new($entryId),
			    RPC::XML::string->new($buzzwords),
			    RPC::XML::string->new($type));
}

sub removeBuzzwords
{
  my $self = shift;
  my ($entryId, $buzzword) = @_;

  return $self->sendRequest(REMOVEBUZZWORDS,
			    RPC::XML::string->new($entryId),
			    RPC::XML::string->new($buzzword));
}

sub getBuzzword
{
  my $self = shift;
  my ($buzzword, $pagesize, $pageNumber) = @_;

  my $rawentries = $self->sendRequest(GETBUZZWORD, 
                                      RPC::XML::string->new($buzzword),
                                      RPC::XML::int->new($pagesize),
                                      RPC::XML::int->new($pageNumber));


  my @entries = ();
  if($rawentries)
  {
    foreach my $entry (@{$rawentries})
    {
      my %hash = %{$entry};
      my $buzznetEntry = Buzznet::Entry->new(%hash);
      push(@entries,$buzznetEntry);
    }
  }

  return @entries;

   
}

sub browseBuzzwords
{
  my $self = shift;
  my $numberBuzzwords = shift;

  my $rawbuzzwords = $self->sendRequest(BROWSEBUZZWORDS, 
                                        RPC::XML::int->new($numberBuzzwords));


  my @buzzwords = ();
  if($rawbuzzwords)
  {
    foreach my $buzzword (@{$rawbuzzwords})
    {
      my %hash = %{$buzzword};
      my $buzznetBuzzword = Buzznet::Buzzword->new(%hash);
      push(@buzzwords,$buzznetBuzzword);
    }
  }

  return @buzzwords;
}

sub updateProfile
{
  my $self = shift;
  my $profile = shift;

  return $self->sendRequest(UPDATEPROFILE,
                            RPC::XML::string->new($profile->password),
                            RPC::XML::string->new($profile->keyword),
                            RPC::XML::string->new($profile->fname),
                            RPC::XML::string->new($profile->lname),
                            RPC::XML::string->new($profile->email),
                            RPC::XML::string->new($profile->address),
                            RPC::XML::string->new($profile->city),
                            RPC::XML::string->new($profile->state),
                            RPC::XML::string->new($profile->zip),
                            RPC::XML::string->new($profile->country),
                            RPC::XML::string->new($profile->dob),
                            RPC::XML::string->new($profile->gender),
                            RPC::XML::string->new($profile->status));
}

sub addFriend
{
  my $self = shift;
  my ($username, $order) = @_;

  
  return $self->sendRequest(ADDFRIEND,
                            RPC::XML::string->new($username),
                            RPC::XML::int->new($order));

}

sub removeFriend
{
  my $self = shift;
  my $username = shift;

  return $self->sendRequest(REMOVEFRIEND, RPC::XML::string->new($username));
}

sub getMyFriends
{
  my $self = shift;

  my $rawfriends = $self->sendRequest(GETMYFRIENDS); 

  my @friends = ();
  if($rawfriends)
  {
    foreach my $friend (@{$rawfriends})
    {
      my %hash = %{$friend};
      my $buzznetFriend = Buzznet::Profile->new(%hash);
      push(@friends,$buzznetFriend);
    }
  }

  return @friends;
}

sub getFriends
{
  my $self = shift;
  my $userId = shift;

  my $rawfriends = $self->sendRequest(GETFRIENDS, RPC::XML::int->new($userId)); 

  my @friends = ();
  if($rawfriends)
  {
    foreach my $friend (@{$rawfriends})
    {
      my %hash = %{$friend};
      my $buzznetFriend = Buzznet::Profile->new(%hash);
      push(@friends,$buzznetFriend);
    }
  }

  return @friends;
  
}

sub getFriendsRecent
{
  my $self = shift;
  my $userId = shift;

  my $rawentries = $self->sendRequest(GETFRIENDSRECENT,
                                      RPC::XML::int->new($userId));


  my @entries = ();
  if($rawentries)
  {
    foreach my $entry (@{$rawentries})
    {
      my %hash = %{$entry};
      my $buzznetEntry = Buzznet::Entry->new(%hash);
      push(@entries,$buzznetEntry);
    }
  }

  return @entries;
}

sub addBookmark
{
  my $self = shift;
  my ($entryId, $type, $order) = @_;

  return $self->sendRequest(ADDBOOKMARK,
                            RPC::XML::string->new($entryId),
                            RPC::XML::string->new($type),
                            RPC::XML::string->new($order));
  
}

sub removeBookmark
{
  my $self = shift;
  my ($entryId, $type) = @_;

  return $self->sendRequest(REMOVEBOOKMARK,
                            RPC::XML::string->new($entryId),
                            RPC::XML::string->new($type));
}

sub getBookmarks
{
  my $self = shift;

  my $rawentries = $self->sendRequest(GETBOOKMARKS);


  my @entries = ();
  if($rawentries)
  {
    foreach my $entry (@{$rawentries})
    {
      my %hash = %{$entry};
      my $buzznetEntry = Buzznet::Entry->new(%hash);
      push(@entries,$buzznetEntry);
    }
  }

  return @entries;
}

sub getMostPopular
{
  my $self = shift;
  my $type = shift;

  my $rawentries = $self->sendRequest(GETMOSTPOPULAR,
                                      RPC::XML::string->new($type));

  my @entries = ();
  if($rawentries)
  {
    foreach my $entry (@{$rawentries})
    {
      my %hash = %{$entry};
      my $buzznetEntry = Buzznet::Entry->new(%hash);
      push(@entries,$buzznetEntry);
    }
  }

  return @entries;
}

sub getTodaysBirthdays
{
  my $self = shift;

  my $rawbirthdays = $self->sendRequest(GETTODAYSBIRTHDAYS);

  my @birthdays = ();
  if($rawbirthdays)
  {
    foreach my $birthday (@{$rawbirthdays})
    {
      my %hash = %{$birthday};
      my $buzznetBirthday = Buzznet::Profile->new(%hash);
      push(@birthdays,$buzznetBirthday);
    }
  }

  return @birthdays;
}

sub getOnlineNow
{
  my $self = shift;
  my $rawonline = $self->sendRequest(GETONLINENOW);

  my @onlines = ();
  if($rawonline)
  {
    foreach my $online (@{$rawonline})
    {
      my %hash = %{$online};
      my $buzznetOnline = Buzznet::Profile->new(%hash);
      push(@onlines,$buzznetOnline);
    }
  }

  return @onlines;
}

sub getFeaturedUsers
{
  my $self = shift;
  my $numberUsers = shift;

  my $rawfeatured = $self->sendRequest(GETFEATUREDUSERS,
                                       RPC::XML::int->new($numberUsers));

  my @featureds = ();
  if($rawfeatured)
  {
    foreach my $featured (@{$rawfeatured})
    {
      my %hash = %{$featured};
      my $buzznetFeatured = Buzznet::Profile->new(%hash);
      push(@featureds,$buzznetFeatured);
    }
  }

  return @featureds;
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Buzznet::API - A Buzznet Photocommunication Client

=head1 SYNOPSIS

	use Buzznet::API;

	# Create the buzznet object with the developer key
	# attained at http://www.buzznet.com/developers 

	my $buzznet = Buzznet::API->new( key => "1234567890",
         	                         username => "developer",
                                 	 password => "password");

	# Leave category blank for default
	my $postId = $buzznet->newPost($filepath, $caption, $body, $category);

=head1 DESCRIPTION

=over 4

Provides an easy to use interface for calling the Buzznet Photocommunications API.

=back

=head1 METHODS

=over 4

=item new( OPTIONS ) 

The constructor that returns a blessed reference to the Buzznet::API instance. See the SYNOPSIS for a sample usage.

=item url( )

Returns the XML-RPC url to the Buzznet API.

=item sendRequest( method_name, [ ARGS ] )

Calls an XML-RPC method on the Buzznet API url with the given ARGS. ARGS must be valid RPC::XML types. This method should only be used for undocumented API methods, since most of the functionality is already defined by other methods in this class. 

Returns either an error, or the RPC::XML response value. 

=item error( )

Returns the most recent error. This should be checked if a call to any of the API methods, or sendRequest returns 0.

=item newPost( filename, caption, body, category ) 

Posts a new image to Buzznet. The filename must point to a valid image file. The category can be an empty string or a subgallery name.

On success, returns the newly created post id; returns 0 on failure

=item editPost( entry_id, filename, caption, body, category )

Updates an existing image post. The entry_id must be owned by the logged in user. The filename must point to a valid image file The category can be an empty string or subgallery name 
	
On success, returns the newly created post id; returns 0 on failure

=item removePost( entry_id )

Removes an image post. The entry_id must be owned by the logged in user. 

=item getEntry( entry_id, type )

Gets a Buzznet entry for the specified entry_id. Type can be either "user" or "cat. 

Returns a Buzznet::Entry object on success, or 0 on failure.

=item addGallery( name, title, description, keyword, password )

Creates a user subgallery. The name of the gallery will later be used as part of the url (e.g. http://kevin-testgallery.buzznet.com/); therefore, the name can only contain letters and numbers. The title is a more verbose representation of the gallery, and will displayed on the welcome page of the gallery.  The keyword is public keyword that can be left empty. Populating this field will allow other's to post to this gallery via email using this keyword wihtout knowing the user's password. The password for the gallery. It can (and should) be left empty. Allows for password-protection on a gallery so only authenticated users with that password can view the photos.

On success, returns the newly created gallery ID, on failure returns 0

=item editGallery( name, title, description, keyword, password )

Edits a user subgallery. The same functionality as the addGallery method, except on an existing subgallery.

On success, returns the gallery ID, on failure returns 0

=item removeGallery( name )

Removes a user subgallery. This causes all the images that were previously in this gallery to be placed back into the main default gallery. The gallery_name must be owned by the logged in user.

Returns 1 on success, 0 on failure.

=item getSubGalleries( username )

Retrieves a list of subgalleries for a particular user. 

Returns an array of Buzznet::Gallery objects on success, or a 0 on failure.

=item getGallery( username, type, user_cat, current_page, pagesize )

Get images from a user or community gallery or user subgallery. The type can be "user" or "cat". If the type is "user", the user_cat can specify a subgallery, otherwise user_cat can be left empty. The current_page is a zero based index into the gallery. The pagesize is the number of images to be returned per page. 

Returns an array of Buzznet::Entry objects on success, or a 0 on failure. 

=item getRecentPosts( type )

Gets the last 12 recent posts from communities or users. The type can be either "user" or "cat". 

Returns an array of Buzznet::Entry objects on success, or a 0 on failure. 

=item getComments( entry_id, type )

Gets a list of comments for a given image. The type can be either "user" or "cat". 

Returns an array of Buzznet::Comment objects on success, or a 0 on failure.

=item addComment( entry_id, comment, type )

Adds a comment to a user or community post. The type can be either "user" or "cat".  

Returns the unique ID of the comment on success, 0 on failure.

=item removeComment( comment_id )

Removes a comment from a user or cateogry post. 

Returns a 1 on success, 0 on failure.

=item getRecentComments( username )

Get comments on the given usernames blog from the past 48 hours. 

Returns an array of Buzznet::Comment objects, 0 on failure.

=item addBuzzwords( entry_id, buzzwords, type )

Add a Buzzword to a post. The buzzwords parameter is a comma-separated string of image keywords. The type can be either "user" or "cat".

=item removeBuzzwords( entry_id, buzzword )

Removes a Buzzword from an image post. 

Returns 1 on success, 0 on failure.

=item getBuzzword( buzzword, pagesize, page_number )

Gets the images associated with a given buzzword. The pagesize is the number of images to return, the page_number is the index of the page. 

Returns an array of Buzznet::Entry objects on success, or 0 on failure

=item browseBuzzwords( number_of_buzzwords )

Gets a list of recent Buzzwords.

Returns an array of Buzznet::Buzzword objects on success, 0 on failure.

=item updateProfile( profile )

Updates the basic profile information of the logged in user. The profile is a populated Buzznet::Profile object. 

=item addFriend( username, order )

Add a user to the friends list of the logged in user. The order is the position this friend should be in the friends list.

=item removeFriend( username )

Removes a friend from the friends list of the logged in user. 

=item getMyFriends( )

Gets a list of friends for the logged in user. 

Returns an array of Buzznet::Profile objects on success, 0 on failure.

=item getFriends( user_id )

Gets a list of friends for the user specified by the user_id. 

Returns an array of Buzznet::Profile objects on success, 0 on failure.

=item getFriendsRecent( user_id )

Gets a list of the most recent entries from the provided user's friends list.

Returns an array of Buzznet::Entry objects on success, 0 on failure.

=item addBookmark( entry_id, type, order )

Adds a bookmark of the entry id to the logged in users profile. Type can be either "user" or "cat". The order specifies where to place this in respect to the other bookmarks

Returns the newly created bookmark_id on success, 0 on failure

=item removeBookmark( entry_id, type )

Removes the specified bookmark for the logged in user. The type can be either "user" or "cat".

Returns 1 on success, 0 on failure

=item getBookmarks( )

Gets a list of the logged in user's bookmarked entries. 

Returns an array of Buzznet::Entry objects on success, 1 on failure.

=item getMostPopular( type ) 

Gets the top 10 most popular user or community posts of the week. Type can be either "user" or "cat".

Returns an array of Buzznet::Entry objects on success, 1 on failure.

=item getTodaysBirthdays( )

Gets a list of users whose birthday is the current day.

Returns an array of Buzznet::Profile objects on success, 1 on failure.

=item getOnlineNow( )

Gets information about last 10 users who are signed in on Buzznet.com

Returns an array of Buzznet::Profile objects on success, 1 on failure.

=item getFeaturedUsers( number_of_users )

Gets a list of users that have been hand-selected as featured users on Buzznet.

Returns an array of Buzznet::Profile objects on success, 1 on failure.

=back

=head1 SEE ALSO

Check out http://www.buzznet.com/developers for the latest tools and
libraries available for all languages and platforms. The complete XML-RPC Buzznet API can be found at http://www.buzznet.com/developers/apidocs/.

Buzznet::Entry
Buzznet::Comment
Buzznet::Profile
Buzznet::Buzzword

=head1 AUTHOR

Kevin Woolery, E<lt>kevin@buzznet.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Kevin Woolery

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

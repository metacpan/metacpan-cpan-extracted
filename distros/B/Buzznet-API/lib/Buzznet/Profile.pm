package Buzznet::Profile;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Buzznet::Profile ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

#require XSLoader;
#XSLoader::load('Buzznet::Profile', $VERSION);

# Preloaded methods go here.

sub new 
{
  my ($package,@refs) = @_;
  my $inst = {@refs};
  $inst->{"error"} = undef;
  return bless($inst,$package);
}

sub password
{
  my $self = shift;
  my $password = shift;

  $self->{"password"} = $password if($password);
  return $self->{"password"};
}

sub keyword
{
  my $self = shift;
  my $keyword = shift;

  $self->{"keyword"} = $keyword if($keyword);
  return $self->{"keyword"};
}

sub fname 
{
  my $self = shift;
  my $fname = shift;

  $self->{"fname"} = $fname if($fname);
  return $self->{"fname"};
}

sub lname
{
  my $self = shift;
  my $lname = shift;

  $self->{"lname"} = $lname if($lname);
  return $self->{"lname"};
}

sub email
{
  my $self = shift;
  my $email = shift;

  $self->{"email"} = $email if($email);
  return $self->{"email"};
}

sub address
{
  my $self = shift;
  my $address = shift;

  $self->{"address"} = $address if($address);
  return $self->{"address"};
}

sub city
{
  my $self = shift;
  my $city = shift;

  $self->{"city"} = $city if($city);
  return $self->{"city"};
}

sub state
{
  my $self = shift;
  my $state = shift;

  $self->{"state"} = $state if($state);
  return $self->{"state"};
}

sub zip
{
  my $self = shift;
  my $zip = shift;

  $self->{"zip"} = $zip if($zip);
  return $self->{"zip"};
}

sub country
{
  my $self = shift;
  my $country = shift;

  $self->{"country"} = $country if($country);
  return $self->{"country"};
}

sub dob
{
  my $self = shift;
  my $dob = shift;

  $self->{"dob"} = $dob if($dob);
  return $self->{"dob"};
}

sub gender
{
  my $self = shift;
  my $gender = shift;

  $self->{"gender"} = $gender if($gender);
  return $self->{"gender"};
}

sub status
{
  my $self = shift;
  my $status = shift;

  $self->{"status"} = $status if($status);
  return $self->{"status"};
}

sub username
{
  my $self = shift;
  return $self->{"user_name"};
}

sub signupdate
{
  my $self = shift;
  return $self->{"signupdate"};
}

sub lastupdated
{
  my $self = shift;
  return $self->{"lastupdated"};
}

sub title
{
  my $self = shift;
  return $self->{"gallery_title"};
}

sub comments
{
  my $self = shift;
  return $self->{"comments"};
}

sub commentsOff
{
  my $self = shift;
  return $self->{"comments_off"};
}

sub anonComments
{
  my $self = shift;
  return $self->{"anon_comments"};
}

sub messagesOff
{
  my $self = shift;
  return $self->{"messages_off"};
}

sub blog
{
  my $self = shift;
  return $self->{"blog"};
}

sub description
{
  my $self = shift;
  return $self->{"description"};
}

sub totalBuddies
{
  my $self = shift;
  return $self->{"totalbuddies"};
}

sub thumbURL
{
  my $self = shift;
  return $self->{"img_thumb"};
}

sub featURL
{
  my $self = shift;
  return $self->{"img_feat"};
}

sub syndURL
{
  my $self = shift;
  return $self->{"img_synd"};
}

sub galleryURL
{
  my $self = shift;
  return $self->{"img_gallery"};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

Buzznet::Profile - Buzznet API Profile Object

=head1 SYNOPSIS

  use Buzznet::Commetn;

=head1 DESCRIPTION

This class encapsulates profile information available from the Buzznet::API. This class is used to update profile information for the logged in user, as well as a value object for friends list and other user lists.

=head1 METHODS

=over 4

=item password

Getter/Setter for the password. Leave this blank on an updateProfile call to
keep the same password. 

Updated with Buzznet::API::updateProfile.

=item keyword

Getter/Setter for the keyword. The keyword is used for posting images. Leave this blank on an updateProfile call to keep the same keyword. 

Updated with Buzznet::API::updateProfile.

=item fname 

Getter/Setter for the first name.

Updated with Buzznet::API::updateProfile.


=item lname

Getter/Setter for the last name.

Updated with Buzznet::API::updateProfile.


=item email

Getter/Setter for the email address.

Updated with Buzznet::API::updateProfile.

=item address

Getter/Setter for the mailing address.

Updated with Buzznet::API::updateProfile.

=item city

Getter/Setter for the city.

Updated with Buzznet::API::updateProfile.

=item state

Getter/Setter for the state.

Updated with Buzznet::API::updateProfile.

=item zip

Getter/Setter for the zip code.

Updated with Buzznet::API::updateProfile.

=item country

Getter/Setter for the country.

Updated with Buzznet::API::updateProfile.

=item dob

Getter/Setter for the date of birth. 

Updated with Buzznet::API::updateProfile.

=item gender

Getter/Setter for the gender ["m"|"f"|""].

Updated with Buzznet::API::updateProfile.

=item status

Getter/Setter for the users single status.
Updated with Buzznet::API::updateProfile.

=item username

Returns the username for this profile.

=item signupdate

Returns the signupdate for this users.

=item lastupdated

Returns the date the user last updated the profile.

=item title

Returns the title of the friends main gallery.

=item commentsOff

Returns whether comments are allowed for this user. 1=user does not allow comments, 0=user allows comments.

=item anonComments

Returns whether anonymous comments are allowed for this user. 1=user allows anonymous comments, 0=user does not allow anonymous comments.

=item messagesOff

Returns whether this user accepts private messages. 1=user has private messagess turned off. 0=user has private messages turned on.

=item blog
 
Returns the URL of the user's outside blog, such as "http://www.livejournal/com/~myname/

=item description

Returns the featured user description if this user is a featured user.

=item totalBuddies

Returns the total number of friends this user has

=item comments

Returns the "About Me" information for a user

=item thumbURL

Returns the url to a thumbnail of the profile image. 

=item featURL

Returns the url to a featured size of the profile image. 

=item syndURL

Returns the url to a syndication size of the profile image. 

=item galleryURL

Returns the url to a gallery size of the profile image. 

=back

=head1 SEE ALSO

Check out http://www.buzznet.com/developers for the latest tools and
libraries available for all languages and platforms. The complete XML-RPC Buzznet API can be found at http://www.buzznet.com/developers/apidocs/.

Buzznet::Entry
Buzznet::Gallery
Buzznet::Profile
Buzznet::API

=head1 AUTHOR

Kevin Woolery, E<lt>kevin@buzznet.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Kevin Woolery

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut


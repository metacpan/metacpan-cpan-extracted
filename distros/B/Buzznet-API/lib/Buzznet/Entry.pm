package Buzznet::Entry;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Buzznet::Entry ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

#require XSLoader;
#XSLoader::load('Buzznet::Entry', $VERSION);

# Preloaded methods go here.

sub new 
{
  my ($package,@refs) = @_;
  my $inst = {@refs};
  $inst->{"error"} = undef;
  return bless($inst,$package);
}

sub categoryID
{
  my $self = shift;
  return $self->{"category_id"};
}

sub time 
{
  my $self = shift;
 
  if(!$self->{"time"})
  {
    return $self->{"utime"};
  }

  return $self->{"time"};
}

sub caption 
{
  my $self = shift;
  return $self->{"caption"};
}

sub body
{
  my $self = shift;
  return $self->{"body"};
}

sub type
{
  my $self = shift;
  return $self->{"mode"};
}

sub name
{
  my $self = shift;
  return $self->{"name"};
}

sub entryId 
{
  my $self = shift;
  return $self->{"entry_id"};
}

sub userId
{
  my $self = shift;
  return $self->{"user_id"};
}

sub username
{
  my $self = shift;
  return $self->{"user_name"};
}

sub category
{
  my $self = shift;
  return $self->{"category"};
}

sub author
{
  my $self = shift;
  return $self->{"author"};
}

sub thumbURL
{
  my $self = shift;
  if(!$self->{"img_thumb"})
  {
    return $self->{"image"};
  }
  return $self->{"img_thumb"};
}

sub galleryURL
{
  my $self = shift;
  return $self->{"img_gallery"};
}

sub featureURL
{
  my $self = shift;
  return $self->{"img_featurl"};
}

sub link
{
  my $self = shift;
  return $self->{"link"};
}

sub bookmarkID
{
  my $self = shift;
  return $self->{"bookmark_id"};
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

Buzznet::Entry - Buzznet API Entry Object

=head1 SYNOPSIS

  use Buzznet::Entry;

=head1 DESCRIPTION

This class is mainly used by Buzznet::API to encapsulate the Comment attributes

=head1 METHODS

=over 4

=item categoryID

Returns the community id if the type is "cat".

=item type

Returns either "user" or "cat".

=item time 

Returns the time of the entry post.

=item caption 

Returns the image caption for the post.

=item body

Returns the body of the post.

=item name

Returns the name of the user or the community blog.

=item entryId 

Returns the entry id for the post.

=item userId

Returns the id of the user or community blog.

=item username

Returns the name of the user or the community blog.

=item category

Returns the user subgallery, or "default" for the main gallery.

=item author

Returns the username of the poster if the type is "cat".

=item thumbURL

Returns the URL to the thumbnail image.

=item galleryURL

Returns the URL to the gallery image.

=item featureURL

Returns the URL to the feature image.

=item link

Returns the permalink for this entry

=item bookmarkID

Returns the bookmark ID for this entry

=back

=head1 SEE ALSO

Check out http://www.buzznet.com/developers for the latest tools and
libraries available for all languages and platforms. The complete XML-RPC Buzznet API can be found at http://www.buzznet.com/developers/apidocs/.

Buzznet::Comment
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


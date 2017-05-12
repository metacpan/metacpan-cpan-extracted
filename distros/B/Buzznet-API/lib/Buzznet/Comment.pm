package Buzznet::Comment;

use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Buzznet::Comment ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

#require XSLoader;
#XSLoader::load('Buzznet::Comment', $VERSION);

# Preloaded methods go here.

sub new 
{
  my ($package,@refs) = @_;
  my $inst = {@refs};
  $inst->{"error"} = undef;
  return bless($inst,$package);
}

sub commentID
{
  my $self = shift;
  return $self->{"entry_comment_id"};
}

sub entryID
{
  my $self = shift;
  return $self->{"entry_id"};
}

sub userID
{
  my $self = shift;
  return $self->{"user_id"};
}

sub time
{
  my $self = shift;
  return $self->{"time"};
}

sub type
{
  my $self = shift;
  return $self->{"type"};
}

sub name
{
  my $self = shift;
  return $self->{"name"};
}

sub comments
{
  my $self = shift;
  return $self->{"comments"};
}

sub username
{
  my $self = shift;
  return $self->{"user_name"};
}

sub image
{
  my $self = shift;
  return $self->{"image"};
}

sub caption
{
  my $self = shift;
  return $self->{"caption"};
}

sub commenterURL
{
  my $self = shift;
  return $self->{"url"};
}

sub commenterImage
{
  my $self = shift;
  return $self->{"user_image"};
}

sub featureURL
{
  my $self = shift;
  return $self->{"entry_image"};
}

sub link
{
  my $self = shift;
  return $self->{"permalink"};
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
=head1 NAME

Buzznet::Comment - Buzznet API Comment Object

=head1 SYNOPSIS

  use Buzznet::Commetn;

=head1 DESCRIPTION

This class is mainly used by Buzznet::API to encapsulate the Comment attributes

=head1 METHODS

=over 4

=item commentID

Returns the unique id of the comment

=item entryID

Returns the id of the image

=item userID

Returns the user id of the commenter, 0 if the commenter is anonymous.

=item type

Returns either "user" or "cat" depending on the type of entry.

=item time

Returns the time the comment was added (format: YYYYMMDDHHmmSS)

=item name

Returns the name of the commenter. This won't always be a real username.

=item comments

Returns the actual comment on the image

=item username

Returns the username of the commenter, if the commenter is a legitimate Buzznet user. If the user is anonymous, this will return "".

=item image

Returns the url to thumbnale image of the commenter

=item caption

Returns the caption of the commented image.

=item commenterURL

Returns the homepage URL of the commenter, "" for anonymous

=item commenterImage

Returns the thumbnail image of the commenter

=item featureURL

Returns the feature size image of the entry being commented 

=item link

Returns a permalink to the comment

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


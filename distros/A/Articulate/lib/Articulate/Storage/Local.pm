package Articulate::Storage::Local;
use strict;
use warnings;

use Moo;
with 'Articulate::Role::Component';
with 'Articulate::Role::Storage';
use Articulate::Syntax qw(hash_merge);

use File::Path;
use IO::All;
use YAML;
use Articulate::Syntax;
use Scalar::Util qw(blessed);
use FindBin;

=head1 NAME

Articulate::Content::Local - store your content locally

=cut

=head1 DESCRIPTION

This content storage interface works by placing content and metadata in
a folder structure.

For a given location, metadata is stored in C<meta.yml>, content in
C<content.blob>.

Set C<content_base> in your config to specify where to place the
content.

Caching is not implemented: get_content_cached simpy calls get_content.

=cut

=head1 METHODS

=cut

has content_base => (
  is      => 'rw',
  lazy    => 1,   # because depends on app
  default => sub {
    my $self = shift;
    return (
      undef

        #  $self->framework->appdir
        // $FindBin::Bin
    ) . '/content/';
  },
  coerce => sub {
    my $content_base = shift;
    unless ( -d $content_base ) {
      File::Path::make_path $content_base;
      throw_error( Internal => 'Could not initialise content base' )
        unless ( -d $content_base );
    }
    return $content_base;
  },
);

sub ensure_exists { # internal method
  my $self               = shift;
  my $true_location_full = shift // return undef;
  my $true_location      = $true_location_full;
  $true_location =~ s~[^/]+\.[^/]+$~~; #:5.12 doesn't have s///r
  unless ( -d $true_location ) {
    File::Path::make_path $true_location;
  }
  return -d $true_location
    ? $true_location_full
    : throw_error( 'Internal' => 'Could not create directory for location' );
}

sub true_location {
  my $self = shift;
  return $self->content_base . shift;
}

=head3 get_item

$storage->get_item( 'zone/public/article/hello-world' )

Retrieves the metadata for the content at that location.

=cut

sub get_item {
  my $self     = shift;
  my $location = shift->location;
  throw_error Internal => "Bad location $location"
    unless $self->navigation->valid_location($location);
  throw_error NotFound => "No content at $location"
    unless $self->item_exists($location);
  my $item = $self->construction->construct( { location => $location } );
  $item->meta( $self->get_meta($item) );
  $item->content( $self->get_content($item) );
  return $item;
}

=head3 get_meta

  $storage->get_meta( 'zone/public/article/hello-world' )

Retrieves the metadata for the content at that location.

=cut

sub get_meta {
  my $self     = shift;
  my $item     = shift;
  my $location = $item->location;
  throw_error Internal => "Bad location $location"
    unless $self->navigation->valid_location($location);
  throw_error NotFound => "No content at $location"
    unless $self->item_exists($location);
  my $fn = $self->true_location( $location . '/meta.yml' );
  return YAML::LoadFile($fn) if -e $fn;
  return {};
}

=head3 set_meta

  $storage->set_meta( 'zone/public/article/hello-world', {...} )

Sets the metadata for the content at that location.

=cut

sub set_meta {
  my $self     = shift;
  my $item     = shift;
  my $location = $item->location;
  throw_error Internal => "Bad location " . $location
    unless $self->navigation->valid_location($location);
  throw_error NotFound => "No content at $location"
    unless $self->item_exists($location);
  my $fn =
    $self->ensure_exists( $self->true_location( $location . '/meta.yml' ) );
  YAML::DumpFile( $fn, $item->meta );
  return $item;
}

=head3 patch_meta

  $storage->patch_meta( 'zone/public/article/hello-world', {...} )

Alters the metadata for the content at that location. Existing keys are
retained.

CURRENTLY this affects top-level keys only, but a descent algorigthm is
planned.

=cut

sub patch_meta {
  my $self     = shift;
  my $item     = shift;
  my $location = $item->location;
  throw_error Internal => "Bad location " . $location
    unless $self->navigation->valid_location($location);
  throw_error NotFound => "No content at $location"
    unless $self->item_exists($location);
  my $fn =
    $self->ensure_exists( $self->true_location( $location . '/meta.yml' ) );
  my $old_data = {};
  $old_data = YAML::LoadFile($fn) if -e $fn;
  return YAML::DumpFile( $fn, hash_merge( $old_data, $item->meta ) );
}

=head3 get_settings

  $storage->get_settings('zone/public/article/hello-world')

Retrieves the settings for the content at that location.

=cut

sub get_settings {
  my $self     = shift;
  my $item     = shift;
  my $location = $item->location;
  throw_error Internal => "Bad location $location"
    unless $self->navigation->valid_location($location);
  throw_error NotFound => "No content at $location"
    unless $self->item_exists($location);
  my $fn = $self->true_location( $location . '/settings.yml' );
  return YAML::LoadFile($fn) if -e $fn;
  return {};
}

=head3 set_settings

  $storage->set_settings('zone/public/article/hello-world', $amended_settings)

Retrieves the settings for the content at that location.

=cut

sub set_settings {
  my $self     = shift;
  my $location = shift->location;
  my $settings = shift;
  throw_error Internal => "Bad location $location"
    unless $self->navigation->valid_location($location);
  throw_error NotFound => "No content at $location"
    unless $self->item_exists($location);
  my $fn =
    $self->ensure_exists( $self->true_location( $location . '/settings.yml' ) );
  YAML::DumpFile( $fn, $settings );
  return $settings;
}

=head3 get_settings_complete

  $storage->get_settings_complete('zone/public/article/hello-world')

Retrieves the settings for the content at that location.

=cut

sub get_settings_complete {
  my $self     = shift;
  my $location = shift->location;
  throw_error Internal => "Bad location $location"
    unless $self->navigation->valid_location($location);
  my @paths        = split /\//, $location;
  my $current_path = $self->true_location('') . '/';
  my $settings     = {};
  foreach my $p (@paths) {
    my $fn           = $current_path . 'settings.yml';
    my $lvl_settings = {};
    $lvl_settings = YAML::LoadFile($fn) if -e $fn;
    $settings = hash_merge( $settings, $lvl_settings );
  }
  return $settings;
}

=head3 get_content

  $storage->get_content('zone/public/article/hello-world')

Retrieves the content at that location.

=cut

sub get_content {
  my $self     = shift;
  my $location = shift->location;
  throw_error Internal => "Bad location $location"
    unless $self->navigation->valid_location($location);
  throw_error NotFound => "No content at $location"
    unless $self->item_exists($location);
  my $fn = $self->true_location( $location . '/content.blob' );
  open my $fh, '<', $fn
    or throw_error Internal => "Cannot open file $fn to read";
  return '' . ( join '', <$fh> );
}

=head3 set_content

  $storage->set_content('zone/public/article/hello-world', $blob);

Places content at that location.

=cut

sub _is_upload {
  my $content = shift;
  return ( blessed $content and $content->isa('Articulate::File') )
    ; # todo: have this wrapped by an articulate class which interfaces with the FrameworkAdapter
}

sub _write_data {
  my ( $content, $fn ) = @_;
  open my $fh, '>', $fn
    or throw_error Internal => "Cannot open file $fn to write";
  print $fh $content;
  close $fh;
}

sub _copy_upload {
  my ( $content, $fn ) = @_;
  my $content_fh = $content->io;
  local $/;
  open my $fh, '>', $fn
    or throw_error Internal => "Cannot open file $fn to write";
  binmode $fh, ':raw';
  print $fn while <$content_fh>;
  close $fh;
}

sub _write_content {
  my ( $content, $fn ) = @_;
  $content //= '';
  if ( _is_upload($content) ) {
    _copy_upload( $content, $fn );
  }
  else {
    _write_data( $content, $fn );
  }
}

sub set_content {
  my $self     = shift;
  my $item     = shift;
  my $location = $item->location;
  throw_error Internal => "Bad location $location"
    unless $self->navigation->valid_location($location);
  throw_error NotFound => "No content at $location"
    unless $self->item_exists($location);
  my $fn =
    $self->ensure_exists( $self->true_location( $location . '/content.blob' ) );
  _write_content( $item->content, $fn );
  return $location;
}

=head3 create_item

  $storage->create_item('zone/public/article/hello-world', $meta, $blob);

Places meta and content at that location.

=cut

sub create_item {
  my $self     = shift;
  my $item     = shift;
  my $location = $item->location;
  throw_error Internal => "Bad location " . $location
    unless $self->navigation->valid_location($location);
  throw_error AlreadyExists => "Cannot create: item already exists at "
    . $location
    if $self->item_exists($location);
  {
    my $fn =
      $self->ensure_exists(
      $self->true_location( $location . '/content.blob' ) );
    _write_content( $item->content, $fn );
  }
  {
    my $fn =
      $self->ensure_exists( $self->true_location( $location . '/meta.yml' ) );
    YAML::DumpFile( $fn, $item->meta );
  }
  $item->content( $self->get_content($item) );
  return $item;
}

=head3 item_exists

  if ($storage->item_exists( 'zone/public/article/hello-world')) {
    ...
  }

Determines if the item has been created (only the C<meta.yml> is
tested).

=cut

sub item_exists {
  my $self     = shift;
  my $location = shift->location;
  throw_error Internal => "Bad location $location"
    unless $self->navigation->valid_location($location);
  return -e $self->true_location( $location . '/meta.yml' );
}

=head3 list_items

  $storage->list_items ('/zone/public'); # 'hello-world', 'second-item' )

Returns a list of items in the.

=cut

sub list_items {
  my $self     = shift;
  my $location = shift->location;

# throw_error Internal => "Bad location $location" unless $self->navigation->valid_location( $location ); # actually, no, because /zone fails but /zone/foo passes
  my $true_location = $self->true_location($location);
  my @contents;
  return @contents unless -d $true_location;
  opendir( my $dh, $true_location )
    or throw_error NotFound => ( 'Could not open ' . $true_location );
  while ( my $fn = readdir $dh ) {
    my $child_dn = $true_location . '/' . $fn;
    next unless -d $child_dn;
    push @contents, $fn
      if $self->navigation->valid_location( $location . '/' . $fn )
      and $self->item_exists( new_location $location. '/' . $fn );
  }
  return @contents;
}

=head3 empty_all_content

  $storage->empty_all_content;

Removes all content. This is totally irreversible, unless you took a
backup!

=cut

sub empty_all_content {
  my $self          = shift;
  my $true_location = $self->content_base;

  throw_error Internal => "Won't empty all content, this looks too dangerous"
    if ( -d "$true_location/.git"
    or -f "$true_location/Makefile.PL" );

  File::Path::remove_tree( $self->content_base, { keep_root => 1 } );
}

=head3 delete_item

  $storage->delete_item ('/zone/public');

Deletes the item and all its descendants.

=cut

sub delete_item {
  my $self     = shift;
  my $location = shift->location;

  throw_error Internal => "Use empty_all_content instead to delete the root"
    if "$location" eq '/';
  throw_error Internal => "Bad location $location"
    unless $self->navigation->valid_location($location);
  throw_error NotFound => "No content at $location"
    unless $self->item_exists($location);

  my $true_location = $self->true_location($location);
  File::Path::remove_tree($true_location);
}

=head1 SEE ALSO

=over

=item * L<Articulate>

=item * L<Articulate::Storage::DBIC::Simple>

=back

=cut

1;

package Catalyst::Controller::AutoAssets::Handler::ImageSet;
use strict;
use warnings;

# VERSION

use Moose;
use namespace::autoclean;

extends 'Catalyst::Controller::AutoAssets::Handler::Directory';

# Whether or not to include parent directories in the image name if this is true, 
# a warning will be thrown if there are any duplicate filenames (and only the
# first will be used)
has 'flatten_paths', is => 'ro', isa => 'Bool', default => 0;

has 'include_regex', is => 'ro', isa => 'Maybe[Str]', default => '\.(png|jpg|jpeg|gif|bmp|tif|tiff|svg)$';
has 'regex_ignore_case', is => 'ro', isa => 'Bool', default => 1;

has 'manifest', is => 'rw', isa => 'HashRef', default => sub {{}};
sub rebuild_manifest {
  my $self = shift;
  
  my $manifest = {};
  for my $path (sort keys %{$self->subfile_meta}) {
    my $name = $path;
    # strip parent directories if flatten_paths is on:
    ($name) = reverse split(/\//,$path) if($self->flatten_paths);
    if(exists $manifest->{$name}) {
      $self->_app->log->warn("Not including duplicate filename '$name' ('$path')");
      next;
    }
    # This is being done this way to make it easy for derived classes to put
    # additional data in the manifest associated with each item
    $manifest->{$name} = { subfile => $path };
  }
  
  $self->manifest($manifest);
}
after set_subfile_meta => sub { (shift)->rebuild_manifest };


around asset_request => sub {
  my ( $orig, $self, $c, $sha1, @args ) = @_;
  
  ## Just for debugging:
  #if($sha1 eq 'dump_manifest') {
  #  $self->clear_asset;
  #  $self->prepare_asset;
  #  
  #  use Data::Dumper::Concise 'Dumper';
  #  $c->response->header('Content-Type' => 'text/plain');
  #  $c->response->body( 
  #    $self->asset_name . ': ' . scalar(keys %{$self->manifest}) . " Items\n\n" .
  #    Dumper($self->manifest)
  #  );
  #  return $c->detach;
  #}
  
  # If we wanted both/either the flattened and orig paths to work we could
  # call $self->_unflatten_path(join('/',@args)) instead below
  return $self->$orig($c, $sha1, $self->_unflatten_path($args[0]))
    if ($self->flatten_paths);

  return $self->$orig($c, $sha1, @args);
};

sub _unflatten_path {
  my ($self, $name) = @_;
  return undef unless (defined $name);
  my $itm = $self->manifest->{$name} or return $name;
  return $itm->{subfile};
}

around _subfile_mtime_verify => sub {
  my ($orig, $self, $path) = @_;
  return $self->$orig($self->_unflatten_path($path));
};

around asset_path => sub {
  my ($orig, $self, @subpath) = @_;
  return $self->flatten_paths 
    ?  join('/',$self->base_path,$self->asset_name,@subpath)
    : $self->$orig(@subpath);
};


has '_persist_attrs', is => 'ro', isa => 'ArrayRef', default => sub{[qw(
 built_mtime
 inc_mtimes
 last_fingerprint_calculated
 subfile_meta
 _excluded_paths
 manifest
)]};


sub img_tag {
  my ($self, @path) = @_;
  my $name = join('/',@path);
  return '<img alt="' . $name . 
    '" src="' . $self->asset_path($name) . '">';
}

sub img_tag_title {
  my ($self, @path) = @_;
  my $name = join('/',@path);
  return '<img alt="' . $name . '" title="' . $name . 
    '" src="' . $self->asset_path($name) . '">';
}


sub dump_all_img_tags {
  my $self = shift;
  return join("\n",map { $self->img_tag_title($_) } (sort keys %{$self->manifest}));
}


1;

__END__

=pod

=head1 NAME

Catalyst::Controller::AutoAssets::Handler::ImageSet - ImageSet type handler

=head1 SYNOPSIS

In your controller:

  package MyApp::Controller::Assets::MyImages;
  use parent 'Catalyst::Controller::AutoAssets';
  
  1;

Then, in your .conf:

  <Controller::Assets::MyImages>
    include        root/images/
    type           ImageSet
    flatten_paths  1
    include_regex  '\.(png|jpg|gif)$'
  </Controller::Assets::MyImages>

And in your .tt files:

  [% c.controller('Assets::MyImages').img_tag('foo.png') %]
  
  <img src="[% c.controller('Assets::MyImages').asset_path('apple.jpg') %]">

Or, in static HTML:

  <img src="/assets/myimages/current/apple.jpg">

=head1 DESCRIPTION

Like the 'Directory' asset type but with some extra options, defaults and functionality specific to images.

This class extends L<Catalyst::Controller::AutoAssets::Handler::Directory>. Only differences are shown below.

=head1 CONFIG PARAMS

=head2 include_regex

Optional regex ($string) to require files to match to be included.

Defaults to C<'\.(png|jpg|jpeg|gif|bmp|tif|tiff|svg)$'>

=head2 regex_ignore_case

Whether or not to use case-insensitive regex (C<qr/$regex/i> vs C<qr/$regex/>) when evaluating 
include_regex/exclude_regex.

Defaults to true (1).

=head2 flatten_paths

Whether or not to convert paths to filenames (i.e. C<'path/to/apple.jpg'> becomes C<'apple.jpg'>) for shorter
and easier names. Duplicate filenames ignored (only the first will be used) with a warning in the log.

Defaults to false (0).

=head1 METHODS

=head2 img_tag

Convenience method to return an HTML img tag for the supplied image/path.

=head2 img_tag_title

Convenience method to return an HTML img tag for the supplied image/path with the 'title' attribute 
(i.e. for mouse-over) set to the path.

=head2 dump_all_img_tags

Dumps img tags for every image in the asset

=head1 SEE ALSO

=over

=item L<Catalyst::Controller::AutoAssets>

=item L<Catalyst::Controller::AutoAssets::Handler>

=item L<Catalyst::Controller::AutoAssets::Handler::Directory>

=item L<Catalyst::Controller::AutoAssets::Handler::IconSet>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

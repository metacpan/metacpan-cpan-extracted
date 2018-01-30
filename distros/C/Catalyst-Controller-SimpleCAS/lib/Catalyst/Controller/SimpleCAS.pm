package Catalyst::Controller::SimpleCAS;
use strict;
use warnings;

# ABSTRACT: General-purpose content-addressed storage (CAS) for Catalyst

our $VERSION = '1.002';

use Moose;
use Types::Standard qw(:all);
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'Catalyst::Controller::SimpleCAS::Role::TextTranscode';

use Catalyst::Controller::SimpleCAS::Content;

use Module::Runtime;
use Try::Tiny;
use Catalyst::Utils;
use Path::Class qw(file dir);
use JSON;
use MIME::Base64;
use String::Random;

use Scalar::Util 'blessed';

has store_class => ( is => 'ro', default => sub {
  '+File'
});

has store_path => ( is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  my $c = $self->_app;
  # Default Cas Store path if none was supplied in the config:
  return dir( Catalyst::Utils::home($c), 'cas_store' )->stringify;
});

has store_args => ( is => 'ro', isa => 'HashRef', lazy => 1, default => sub {
  my $self = shift;
  return {
    store_dir => $self->store_path,
  };
});

has Store => (
  does => 'Catalyst::Controller::SimpleCAS::Store',
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;
    my $class = $self->store_class;
    if ($class =~ m/^\+([\w:]+)/) {
      $class = 'Catalyst::Controller::SimpleCAS::Store::'.$1;
    }
    Module::Runtime::require_module($class);
    return $class->new(
      simplecas => $self,
      %{$self->store_args},
    );
  },
  handles => [qw(
    file_checksum
    calculate_checksum
  )],
);


### ----------------------------------------------------------------------
### New sugar/convenience methods:
###
sub fetch { 
  my ($self, $cas_id) = @_;
  $self->uri_find_Content($cas_id) 
}

sub fetch_fh {
  my ($self, $cas_id) = @_;
  my $checksum = $self->_find_prune_checksum($cas_id) or return undef;
  $self->Store->fetch_content_fh($checksum)
}

sub add {
  my $self = shift;
  my $cnt = shift;
  
  my $content = '';
  
  if(my $type = ref $cnt) {
    if($type eq 'SCALAR') {
      $content = $$cnt;
    }
    elsif(blessed $cnt && $cnt->can('getline')) {
      while(my $line = $cnt->getline) {
        $content .= $line;
      }
    }
    else {
      die "Bad content argument $cnt!";
    }
  }
  else {
    $content = $cnt;
  }
  
  # Is this a file name?
  return $self->Store->add_content_file($content) if (
    length($content) < 1024 && 
    !($content =~ /\n/) &&
    -f $content
  );

  return $self->Store->add_content($content)
}
###
### ----------------------------------------------------------------------


#has 'fetch_url_path', is => 'ro', isa => 'Str', default => '/simplecas/fetch_content/';

sub Content {
  my $self = shift;
  my $checksum = shift;
  my $filename = shift; #<-- optional
  return Catalyst::Controller::SimpleCAS::Content->new(
    Store     => $self->Store,
    checksum  => $checksum,
    filename  => $filename
  );
}

# Accepts a free-form string and tries to extract a Cas checksum string from it. If the
# checksum exists, thr pruned checksum string is returned
sub _find_prune_checksum {
  my $self = shift;
  my $uri = shift or return undef;
  my @parts = split(/\//,$uri);
  
  while (scalar @parts > 0) {
    my $checksum = shift @parts;
    next unless ($checksum =~ /^[0-9a-f]{40}$/);
    return $checksum if ($self->Store->content_exists($checksum));
  }
  return undef;
}

# Accepts a free-form string and tries to extract a Cas checksum and 
# filename from it. If it is successfully, and the checksum exists in 
# the Store, returns the Content object
sub uri_find_Content {
  my $self = shift;
  my $uri = shift or return undef;
  my @parts = split(/\//,$uri);
  
  while (scalar @parts > 0) {
    my $checksum = shift @parts;
    next unless ($checksum =~ /^[0-9a-f]{40}$/);
    my $filename = (scalar @parts == 1) ? $parts[0] : undef;
    my $Content = $self->Content($checksum,$filename) or next;
    return $Content;
  }
  return undef;
}

sub base :Chained :PathPrefix :CaptureArgs(0) {}

sub fetch_content :Chained('base') :Args {
  my ($self, $c, $checksum, $filename) = @_;
  
  my $disposition = 'inline;filename="' . $checksum . '"';
  
  if ($filename) {
    $filename =~ s/\"/\'/g;
    $disposition = 'attachment; filename="' . $filename . '"';  
  }
  
  unless($self->Store->content_exists($checksum)) {
    $c->res->body('Does not exist');
    return;
  }
  
  my $type = $self->Store->content_mimetype($checksum) or die "Error reading mime type";
  
  # type overrides for places where File::MimeInfo::Magic is known to guess wrong
  if($type eq 'application/vnd.ms-powerpoint' || $type eq 'application/zip') {
    my $Content = $self->Content($checksum,$filename);
    my $ext = lc($Content->file_ext);
    $type = 
      $ext eq 'doc'  ? 'application/msword' :
      $ext eq 'xls'  ? 'application/vnd.ms-excel' :
      $ext eq 'docx' ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' :
      $ext eq 'xlsx' ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' :
      $ext eq 'pptx' ? 'application/vnd.openxmlformats-officedocument.presentationml.presentation' :
    $type;
  }
  
  $c->response->header('Content-Type' => $type);
  $c->response->header('Content-Disposition' => $disposition);
  return $c->res->body( $self->Store->fetch_content_fh($checksum) );
}


sub upload_content :Chained('base') :Args {
  my ($self, $c) = @_;

  my $upload = $c->req->upload('Filedata') or die "no upload object";
  my $checksum = $self->Store->add_content_file_mv($upload->tempname) or die "Failed to add content";
  
  return $c->res->body($checksum);
}


sub upload_image :Chained('base') :Args {
  my ($self, $c, $maxwidth, $maxheight) = @_;

  my $upload = $c->req->upload('Filedata') or die "no upload object";

  my ($type,$subtype) = split(/\//,$upload->type);
  
  my $resized = \0;
  my $shrunk = \0;
  
  my ($checksum,$width,$height,$orig_width,$orig_height);

  if($self->_is_image_resize_available) {
    # When Image::Resize is available:
    ($checksum,$width,$height,$resized,$orig_width,$orig_height) 
      = $self->add_resize_image($upload->tempname,$type,$subtype,$maxwidth,$maxheight);
  }
  else {
    # Fall-back calculates new image size without actually resizing it. The img
    # tag will still be smaller, but the image file will be original dimensions
    ($checksum,$width,$height,$shrunk,$orig_width,$orig_height) 
      = $self->add_size_info_image($upload->tempname,$type,$subtype,$maxwidth,$maxheight);
  }
  
  
  unlink $upload->tempname;
  
  #my $tag = '<img src="/simplecas/fetch_content/' . $checksum . '"';
  #$tag .= ' width=' . $width . ' height=' . $height if ($width and $height);
  #$tag .= '>';
  
  # TODO: fix this API!!!
  
  my $packet = {
    success => \1,
    checksum => $checksum,
    height => $height,
    width => $width,
    resized => $resized,
    shrunk => $shrunk,
    orig_width => $orig_width,
    orig_height => $orig_height,
    filename => $self->safe_filename($upload->filename),
  };
  
  return $self->_json_response($c, $packet);
}

sub _is_image_resize_available {
  my $flag = 1;
  try   { Module::Runtime::require_module('Image::Resize') }
  catch { $flag = 0 };
  $flag
}


sub add_resize_image :Private {
  my ($self,$file,$type,$subtype,$maxwidth,$maxheight) = @_;
  
  my $checksum = $self->Store->add_content_file($file) or die "Failed to add content";
  
  my $resized = \0;
  
  my ($width,$height) = $self->Store->image_size($checksum);
  my ($orig_width,$orig_height) = ($width,$height);
  if (defined $maxwidth) {
    
    my ($newwidth,$newheight) = ($width,$height);
    
    if($width > $maxwidth) {
      my $ratio = $maxwidth/$width;
      $newheight = int($ratio * $height);
      $newwidth = $maxwidth;
    }
    
    if(defined $maxheight and $newheight > $maxheight) {
      my $ratio = $maxheight/$newheight;
      $newwidth = int($ratio * $newwidth);
      $newheight = $maxheight;
    }
    
    unless ($newwidth == $width && $newheight == $height) {
    
      my $image = Image::Resize->new($self->Store->checksum_to_path($checksum));
      my $gd = $image->resize($newwidth,$newheight);
      
      my $method = 'png';
      $method = $subtype if ($gd->can($subtype));
      
      my $tmpfile = file(
        Catalyst::Utils::class2tempdir($self->_app,1),
        String::Random->new->randregex('[a-z0-9A-Z]{15}')
      );
      
      $tmpfile->spew( $gd->$method );
      
      my $newchecksum = $self->Store->add_content_file_mv($tmpfile->stringify);
      
      ($checksum,$width,$height) = ($newchecksum,$newwidth,$newheight);
      $resized = \1;
    }
  }
  
  return ($checksum,$width,$height,$resized,$orig_width,$orig_height);
}


# New method, uses the same API as 'add_resize_image' above, but doesn't
# do any actual resizing (just calculates smaller height/width for better
# display). This method is used when Image::Resize is not available.
# Added for RapidApp Github Issue #42
sub add_size_info_image :Private {
  my ($self,$file,$type,$subtype,$maxwidth,$maxheight) = @_;

  my $checksum = $self->Store->add_content_file($file) or die "Failed to add content";

  my $shrunk = \0;

  my ($width,$height) = $self->Store->image_size($checksum);

  my ($orig_width,$orig_height) = ($width,$height);
  if (defined $maxwidth) {
    
    my ($newwidth,$newheight) = ($width,$height);
    
    if($width > $maxwidth) {
      my $ratio = $maxwidth/$width;
      $newheight = int($ratio * $height);
      $newwidth = $maxwidth;
    }
    
    if(defined $maxheight and $newheight > $maxheight) {
      my $ratio = $maxheight/$newheight;
      $newwidth = int($ratio * $newwidth);
      $newheight = $maxheight;
    }
    
    unless ($newwidth == $width && $newheight == $height) {
      ($width,$height) = ($newwidth,$newheight);
      $shrunk = \1;
    }
  }

  return ($checksum,$width,$height,$shrunk,$orig_width,$orig_height);
}


sub upload_file :Chained('base') :Args {
  my ($self, $c) = @_;
  
  my $upload = $c->req->upload('Filedata') or die "no upload object";
  my $checksum = $self->Store->add_content_file_mv($upload->tempname) or die "Failed to add content";
  my $Content = $self->Content($checksum,$upload->filename);
  
  my $packet = {
    success  => \1,
    filename => $self->safe_filename($upload->filename),
    checksum  => $Content->checksum,
    mimetype  => $Content->mimetype,
    css_class => $Content->filelink_css_class,
  };
  
  return $self->_json_response($c, $packet);
}


sub safe_filename {
  my $self = shift;
  my $filename = shift;
  
  my @parts = split(/[\\\/]/,$filename);
  return pop @parts;
}


sub upload_echo_base64 :Chained('base') :Args {
  my ($self, $c) = @_;

  my $upload = $c->req->upload('Filedata') or die "no upload object";
  
  my $base64 = encode_base64($upload->slurp,'');
  
  my $packet = {
    success => \1,
    echo_content => $base64
  };
  
  return $self->_json_response($c, $packet);
}


has '_json_view_name', is => 'ro', isa => Maybe[Str], lazy => 1, default => sub {
  my $self = shift;
  my $c = $self->_app;
  my %views = map {$_=>1} $c->views;
  
  # If we're in a RapidApp application (or the RapidApp::JSON view is available),
  # use it. This is needed to do the special embedded iframe encoding when the
  # RequestContentType => 'text/x-rapidapp-form-response' header is present. This
  # is set from the RapidApp/ExtJS client when doing uploads for things like 'Insert Image'
  my $vn = 'RapidApp::JSON';
  
  $views{$vn} ? $vn : undef
};


sub _json_response {
  my ($self, $c, $packet) = @_;
  
  $c->stash->{jsonData} = encode_json($packet);
  
  if(my $vn = $self->_json_view_name) {
    my $view = $c->view( $vn ) or die "No such view name '$vn'";
    $c->forward( $view );
  }
  else {
    $c->res->content_type('application/json; charset=utf-8');
    $c->res->body( $c->stash->{jsonData} );
  }
}

1;


__END__

=head1 NAME

Catalyst::Controller::SimpleCAS - General-purpose content-addressed storage (CAS) for Catalyst

=head1 SYNOPSIS

 use Catalyst::Controller::SimpleCAS;
 ...

See the SYNOPSIS of L<Catalyst::Plugin::SimpleCAS> for the standard use/examples.

=head1 DESCRIPTION

This controller provides a simple content-addressed storage backend for Catalyst applications. The
concept of content-addressed storage ("CAS") is to store arbitrary content in a simple indexed 
key/value database where the "key" is the SHA1 checksum of the "value". This is the same design
and theory used by Git.

This module was originally developed for and within L<RapidApp> before being extracted into its 
own module. This module provides server-side functionality which can be used for any Catalyst 
application, however, it is up to the developer to write the associated front-end interfaces to 
consume its API (unless you are using RapidApp to begin with). RapidApp already has a number of 
built-in features and interfaces which rely on this module for backend storage, including, 
C<cas_link> (file attachment columns) and C<cas_img> (image columns) column profiles, as well as 
the ability to insert images and file links directly within rich template content and C<html> 
columns using WYSIWYG editors.

The type of content this module is designed to store are simple files (with some extra handling
for images specifically). For the purposes of security, we rely on the assumption that knowing the 
checksum of the content is equivalent to being authorized to view that content. So the checksums
are also considered the authorization tokens to access the data, so keeping the checksums themselves
secure is the only way to keep the associated data/content secret. If you understand what this means
B<AND> you feel that this is insufficient security, don't use this module (or, extend it and add 
whatever additional security/authorization/permission checks you feel are necessary)

Starting in version 1.000 of this module, L<Catalyst::Plugin::SimpleCAS> is now provided and is the
way RapidApp consumes and uses this module, and is the standard way to use this module in any 
Catalyst application, for most scenarios. The plugin simply injects a single controller instance of 
C<Catalyst::Controller::SimpleCAS> as 'SimpleCAS' which is all that is needed for most setups. The 
only reason to use the controller class directly would be if you needed multiple controllers in the 
same app, or if you wanted to subclass or do something else fancy.

The ATTRUBUTES listed below can be configured in your Catalyst config in the normal manner using the 
C'<Controller::SimpleCAS'> config key (assuming you used L<Catalyst::Plugin::SimpleCAS> with the
default C<controller_namespace> of 'SimpleCAS'). No options are required, with the defaults being
sufficient in most cases (including the way this module is used by L<RapidApp>).

=head1 ATTRIBUTES

=head2 store_class

Object class to use for the Store backend. Defaults to 
C<Catalyst::Controller::SimpleCAS::Store::File>

=head2 store_path

Directory/path to be used by the Store. Defaults to C<cas_store/> within the Catalyst home directory.
This is a convenience param to supply to the Store, which becomes C<store_dir> for the default
L<Catalyst::Controller::SimpleCAS::Store::File> store class. 

The rationale behind the name 'store_path' instead of 'store_dir' as it becomes in the default store
is the notion that a single "path" argument is all that most Stores need, and different stores may
treat this value as something other than a filesystem directory, so it was intentionally given the
more ambiguous name. For most users that will use basic/default options, these details aren't important.

=head2 store_args

Optional options (HashRef) to supply when contructing the Store. This is only needed for custom
Stores which need more options beyond store_path.

=head2 Store

Actual object instance of the Store. By default this object is built using the C<store_class> (by 
calling C<new()>) with the C<store_path> supplied to the constructor.

=head2 _json_view_name

Name of an optional Catalyst View to forward to to render JSON responses, with the pre-encoded 
JSON set in the stash key 'jsonData'. If not set, the encoded JSON is simply set in response body 
with the Content-Type set to C<application/json>.

If the view name C<RapidApp::View> is loaded (which is the case when L<RapidApp> is loaded),
it is used as the default. This is needed to support special round-trip encodings for 
"Insert Image" and other ExtJS-based upload interfaces.


=head1 PUBLIC ACTIONS

=head2 upload_content

Upload new content to the CAS and return the sha1 checksum in the body to be able to access it later. 
Because of the CAS design, the system automatically deduplicates, and will only ever store
a single copy of a given unique piece of content in the Store. 

=head2 fetch_content

Fetch existing content from the CAS according its sha1 checksum. 

Example:

  GET /simplecas/fetch_content/fdb379f7e9c8d0a1fcd3b5ee4233d88c5a4a023e

The system attempts to identify the content type and sets the MIME type accordingly. Additionally,
an optional filename argument can be also be supplied in the URL

  GET /simplecas/fetch_content/fdb379f7e9c8d0a1fcd3b5ee4233d88c5a4a023e/somefile.txt

The main reason this is supported is simply for more human-friendly URLs. The name is not stored
or validated in any way. If supplied, this does nothing other than being used to set the 
content-disposition:

  Content-Disposition: attachment; filename="somefile.txt"

When there is no filename second arg supplied, the content-disposition is set like this:

  Content-Disposition: inline;filename="fdb379f7e9c8d0a1fcd3b5ee4233d88c5a4a023e"

=head2 upload_file

Works like C<upload_content>, but returns a JSON packet with additional metadata/information in
the body.

=head2 upload_image

Works like C<upload_file>, but with some image-specific functionality, including client-supplied
max width and height values supplied as the first and second args, respectively. For example,
a POST I<upload> with I<Filedata> containing an image, and declared max size of 800x600 uses a
URL like:

  POST /simplecas/upload_image/800/600

When the image is larger than the max width or height, I<if> the optional dependency 
L<Image::Resize> is available (which requires L<GD>) it is used to resize the image, preserving
height/width proportions accordingly, and the new, resized image is what is stored in the CAS.
Otherwise, the image is not resized, but resized dimensions are returned in the JSON packet
so the client can generate an C<img> tag for display.

Originally, L<Image::Resize> was a standard dependency, but this can be a PITA to get installed
with all of the dependencies of L<GD>.

=head2 upload_echo_base64

This does nothing but accept a standard POST/Filedata upload and return it as base64 in a JSON
packet within the JSON/object key C<echo_content>.

=head2 base

This is the base action of the Catalyst Chain behind this asset controller. So
far it still is a fixed position, but we will allow in a later version to set
the Chained base to any other action via configuration.

You could override specific URLs inside the SimpleCAS with own controllers,
you just chain to this base controller, but we would strongly advice to put
those outside functionalities next to this controller.

=head1 METHODS

=head2 fetch

Convenience method to fetch the content (as a raw string/scalar) associated with a cas_id string
which can be simply be the 40-character checksum by itself, or the checksum with a filename
as generated by RapidApp's C<cas_link> and C<cas_img> column profiles.

This method is provided as sugar for the purposes of interacting with the CAS from backend 
scripts/code, rather than via HTTP requests to the controller actions.

=head2 fetch_fh

Like C<fetch> but returns the content as a filehandle (i.e. L<IO::File>, or whatever IO object
the given Store returns).

=head2 add

Convenience method to add content to the CAS and return the checksum. Content argument can be 
supplied as a simple Scalar (i.e. raw string/data), a ScalarRef, a filehandle (i.e. an object 
which derives from L<IO::Handle> or otherwise is an object with an appropriate C<'getlines'>
method, or a filesystem path.

This method is provided as sugar for the purposes of interacting with the CAS from backend 
scripts/code, rather than via HTTP requests to the controller actions.

=head2 Content

Not usually called directly

=head2 add_resize_image

Not usually called directly

=head2 add_size_info_image

Not usually called directly

=head2 safe_filename

Not usually called directly

=head2 uri_find_Content

Not usually called directly

=head2 calculate_checksum

=head2 file_checksum

=head1 SEE ALSO

=over

=item *

L<Catalyst::Plugin::SimpleCAS>

=item *

L<Catalyst>

=item *

L<Catalyst::Controller>

=item * 

L<RapidApp>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

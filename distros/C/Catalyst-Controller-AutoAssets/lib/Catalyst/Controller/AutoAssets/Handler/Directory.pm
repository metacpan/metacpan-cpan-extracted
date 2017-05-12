package Catalyst::Controller::AutoAssets::Handler::Directory;
use strict;
use warnings;

# VERSION

use Moose;
use namespace::autoclean;

with 'Catalyst::Controller::AutoAssets::Handler';

use Path::Class 0.32 qw( dir file );
use MIME::Types;


sub BUILD {
  my $self = shift;
  
  # init dir_root:
  $self->dir_root;
}

sub asset_request {
  my ( $self, $c, $sha1, @args ) = @_;
  
  # Only subfiles are valid with Directory assets:
  return $self->unknown_asset($c) unless (scalar @args > 0);
  
  my $path = join('/',@args);
  $self->prepare_asset($path);

  return $self->unknown_asset($c) unless (
    $sha1 eq $self->asset_name
    && exists $self->subfile_meta->{$path}
  );

  my $meta = $self->subfile_meta->{$path};
  return $self->_set_file_response($c,$meta->{file},$meta->{content_type});
}

sub _set_file_response {
  my ($self, $c, $file, $content_type) = @_;
  
  $c->response->header(
    'Content-Type' => $content_type,
    'Cache-Control' => $self->cache_control_header
  );

  my $f= $file->openr;
  binmode $f;
  return $c->response->body( $f );
}


sub _resolve_subfile_content_type {
  my $self = shift;
  my $File = shift;
  my $content_type = $self->subfile_meta->{$File}->{content_type}
    or die "content_type not found in subfile_meta for $File!";
  return $content_type;
}

# CodeRef used to determine the Content-Type of each 'directory' subfile
has 'content_type_resolver', is => 'ro', isa => 'CodeRef', default => sub{ \&_ext_to_type };

has 'MimeTypes', is => 'ro', isa => 'MIME::Types', lazy => 1, default => sub {
  my $self = shift;
  return MIME::Types->new( only_complete => 1 );
};

# looks up the correct MIME type for the current file extension
# (adapted from Static::Simple)
sub _ext_to_type {
  my ( $self, $full_path ) = @_;
  my $c = $self->_app;

  if ( $full_path =~ /.*\.(\S{1,})$/xms ) {
    my $ext = $1;
    my $type = $self->MimeTypes->mimeTypeOf( $ext );
    if ( $type ) {
      return ( ref $type ) ? $type->type : $type;
    }
    else {
      return 'text/plain';
    }
  }
  else {
    return 'text/plain';
  }
}

# subfile_meta applies only to 'directory' assets. It is a cache of mtimes of
# individual files within the directory since 'inc_mtimes' only conatins the top
# directory. This is used to check for mtime changes on individual subfiles when
# they are requested. This is for performance since it would be too expensive to
# attempt to check all the mtimes on every request
has 'subfile_meta', is => 'rw', isa => 'HashRef', default => sub {{}};
sub set_subfile_meta {
  my $self = shift;
  my $list = shift;
  $self->subfile_meta({
    map { join('/', grep { $_ ne '.' } $_->relative($self->dir_root)->components) => {
      file => $_,
      mtime => $_->stat->mtime,
      content_type => $self->content_type_resolver->($self,$_)
    } } @$list
  });
}

has '_persist_attrs', is => 'ro', isa => 'ArrayRef', default => sub{[qw(
 built_mtime
 inc_mtimes
 last_fingerprint_calculated
 subfile_meta
 _excluded_paths
)]};


has 'dir_root', is => 'ro', isa => 'Path::Class::Dir', lazy => 1, default => sub {
  my $self = shift;

  die "'directory' assets must have exactly one include path"
    unless (scalar @{$self->includes} == 1);

  my $dir = $self->includes->[0]->absolute;
  die "include path '$dir' is not a directory" unless (-d $dir);

  return $dir;
};

sub _subfile_mtime_verify {
  my ($self, $path) = @_;
  my $File = $self->dir_root->file($path);
  
  # If the file doesn't exist on disk or is in the excluded paths there 
  # is no need to clear the asset. We already know it will return a 404
  return if ($self->_excluded_paths->{$path} || ! -f $File);

  # Check the mtime of the requested file to see if it has changed
  # and force a rebuild if it has. This is done because it is too
  # expensive to check all the subfile mtimes on every request, and
  # changes within files would not otherwise be caught since file
  # content changes do not update the parent directory mtime
  $self->clear_asset unless (
    exists $self->subfile_meta->{$path} &&
    $File->stat->mtime eq $self->subfile_meta->{$path}->{mtime}
  );
}

# Provides a mechanism for preparing a set of subfiles all at once. This
# is a critical pre-step whenever multiple subfiles are being used together
# because if any have changed the asset path for *all* will be updated as
# soon as the changed file is detected. If this happens halfway through the list,
# the asset path of earlier processed items will retroactively change.
sub prepare_asset_subfiles {
  my ($self, @files) = @_;
  $self->_subfile_mtime_verify($_) for (@files);
  $self->prepare_asset;
}

around asset_path => sub {
  my ($orig, $self, @subpath) = @_;
  
  my $base = $self->$orig(@subpath);
  return $base unless (scalar @subpath > 0);

  my $File = $self->dir_root->file(@subpath);
  Catalyst::Exception->throw("sub file $File not found") unless (-f $File);

  return join('/',$base,@subpath);
};

sub before_prepare_asset {
  my ($self, @args) = @_;
  my $path = join('/',@args);
  
  # Special code path: if this is associated with a sub file request
  # in a 'directory' type asset, clear the asset to force a rebuild
  # below if the *subfile* mtime has changed
  $self->_subfile_mtime_verify($path) if (scalar @args > 0);
}

sub get_prepare_data {
  my $self = shift;
  
  # For 'directory' only consider the mtime of the top directory and don't
  # read in all the files (yet... we will read them in only if we need to rebuild)
  #  WARNING: this means that changes *within* sub files will not be detected here
  #  because that doesn't update the directory mtime; only filename changes will be seen.
  #  Update: That is what _subfile_mtime_verify above is for... to inexpensively catch
  #  this case for individual sub files
  my $files = $self->includes;
  my $inc_mtimes = $self->get_inc_mtime_concat($files);
  my $built_mtime = $self->get_built_mtime;
  
  return {
    files => $files,
    inc_mtimes => $inc_mtimes,
    built_mtime => $built_mtime
  };
}

around build_asset => sub {
  my ($orig, $self, $d) = @_;
  
  # Get the real list of files that we put off in get_prepare_data()
  $d->{files} = $self->get_include_files;

  # update the mtime cache of all directory subfiles
  $self->set_subfile_meta($d->{files});

  return $self->$orig($d);
};

# Keep track of excluded files so we can return a 404 without rebuilding
# the asset
has '_excluded_paths', is => 'rw', isa => 'HashRef', default => sub {{}};
sub _record_excluded_files {
  my ($self, $files) = @_;
  my @relative = map { join('/', grep { $_ ne '.' } file($_)->relative($self->dir_root)->components) } @$files;
  my %hash = map { $_ => 1 } map { "$_" } @relative;
  $self->_excluded_paths(\%hash);
}

sub write_built_file {
  my ($self, $fd, $files) = @_;
  # The built file is just a placeholder in the case of 'directory' type 
  # asset whose data is served from the original files
  my @relative = map { join('/', grep { $_ ne '.' } file($_)->relative($self->dir_root)->components) } @$files;
  $fd->write(join("\r\n",@relative) . "\r\n");
}


# These apply only to 'directory' asset type
has 'html_head_css_subfiles', is => 'ro', isa => 'ArrayRef', default => sub {[]};
has 'html_head_js_subfiles', is => 'ro', isa => 'ArrayRef', default => sub {[]};

# --------------------
# html_head_tags()
#
# Convenience method to generate a set of CSS <link> and JS <script> tags
# suitable to drop into the <head> section of an HTML document. 
#
# For 'css' and 'js' assets this will be a single tag pointing at the current
# valid asset path. For 'directory' asset types this will be a listing of
# css and/or js tags pointing at subfile asset paths supplied in the attrs:
# 'html_head_css_subfiles' and 'html_head_js_subfiles', or, supplied in a
#  hash(ref) argument with 'css' and/or 'js' keys and arrayref values.
#
# ### More about the 'directory' asset type:
#
# This could be considered a violation of separation of concerns, but the main
# reason this method is provided at all, besides the fact that it is a common
# use case, is that it handles the preprocessing required to ensure the dir asset
# is in an atomic/consistent state by calling prepare_asset_subfiles() on all
# supplied subfiles as a group to catch any content changes before rendering/returning
# the active asset paths. This is something that users might not realize they
# need to do if they don't read the docs closely. So, it is a common use case
# and this provides a simple and easy to understand interface that spares the user
# from needing to know about details they might not want to know about. It's
# practical/useful, self-documenting, and doesn't have to be used...
#
# The only actual "risk" if this the preprocessing step is missed, and the user builds
# head tags themselves with multiple calls to asset_path('path/to/subfile') [such as in
# a TT file] is that during a request where the content of one of the subfiles has changed,
# the asset paths of all the subfiles processed/returned prior to hitting the changed file
# will already be invalid (retroactively) because the sha1 will have changed. This is
# because the sha1/fingerprint is based on the asset as *whole*, and for performance, subfile
# content changes are not detected until they are accessed. This is only an issue when the
# content changes *in-place*, which shouldn't happen in a production environment. And, it
# only effects the first request immediately after the change. This issue can also be avoided
# altogether by using static 'current' alias redirect URLs instead off calling asset_path(),
# but this is *slightly* less efficient, as discussed in the documentation.
#
# This long-winded explanation is more about documenting/explaining the internal design
# for development purposes (and to be a reminder for me) than it is anything else. Also,
# it is intentionally in a comment rather than the POD for the sake of avoiding information
# overload since from the user perspective this is barely an issue (but very useful for
# developers who need to understand the internals of this module)
#
#  Note: This has nothing to do with 'css' or 'js' asset types which are always atomic
#  (because they are single files and have no "subfiles"). This *only* applies to
#  the 'directory' asset type
#
sub html_head_tags {
  my ($self, @args) = @_;

  # get the files from either supplied arguments or defaults in object attrs:
  my %cnf = scalar @args > 0
    ? ( (ref($args[0]) eq 'HASH') ? %{ $args[0] } : @args ) # <-- arg as hash or hashref
    : ( css => $self->html_head_css_subfiles, js => $self->html_head_js_subfiles );
    
  # note that we're totally trusting the caller to know that these files are
  # in fact js/css files. We're just generating the correct tags for each type
  my @css = $cnf{css} ? @{$cnf{css}} : ();
  my @js = $cnf{js} ? @{$cnf{js}} : ();

  # This is the line that ensures any content changes are detected before we start
  # building the tags/urls:
  $self->prepare_asset_subfiles(@css,@js);

  # This spares repeating the stat/mtime calls by asset_path() below.
  # Maybe overkill, but every little bit of performance helps (and I'm OCD)...
  $self->_asset_path_skip_prepare(1);
  
  my @tags = ();
  
  push @tags, '<link rel="stylesheet" type="text/css" href="' .
    $self->asset_path($_) . '" />' for (@css);

  push @tags, '<script type="text/javascript" src="' .
    $self->asset_path($_) . '"></script>' for (@js);

  # FIXME: shame on me
  $self->_asset_path_skip_prepare(0);
  
  my $html =
		"<!--   AUTO GENERATED BY " . ref($self->Controller) . " (/" .
    $self->action_namespace($self->_app) . ")   -->\r\n" .
		( scalar @tags > 0 ?
			join("\r\n",@tags) : '<!--      NO ASSETS AVAILABLE      -->'
		) .
		"\r\n<!--  ---- END AUTO GENERATED ASSETS ----  -->\r\n";

  return $html;
}
# --------------------

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::AutoAssets::Handler::Directory - Directory type handler

=head1 DESCRIPTION

This is the Handler class for the 'Directory' asset type. This is a core type and is
documented in L<Catalyst::Controller::AutoAssets>.

=head1 SEE ALSO

=over

=item L<Catalyst::Controller::AutoAssets::Handler>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


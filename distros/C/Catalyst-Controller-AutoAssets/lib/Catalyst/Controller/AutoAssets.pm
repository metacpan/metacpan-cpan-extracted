package Catalyst::Controller::AutoAssets;
use strict;
use warnings;

our $VERSION = '0.40';

use Moose;
use namespace::autoclean;
require Module::Runtime;

BEGIN { extends 'Catalyst::Controller' }

has 'type', is => 'ro', isa => 'Str', required => 1;
has 'no_logs', is => 'rw', isa => 'Bool', default => sub {1};

has '_module_version', is => 'ro', isa => 'Str', default => $VERSION;

# Save the build params (passed to constructor)
has '_build_params', is => 'ro', isa => 'HashRef', required => 1;
around BUILDARGS => sub {
  my ($orig, $class, $c, @args) = @_;
  my %params = (ref($args[0]) eq 'HASH') ? %{ $args[0] } : @args; # <-- arg as hash or hashref
  $params{_build_params} = {%params};
  return $class->$orig($c,\%params);
};

# The Handler (which is determined by the asset type) is 
# where most of the actual work gets done:
has '_Handler' => (
  is => 'ro', init_arg => undef, lazy => 1,
  does => 'Catalyst::Controller::AutoAssets::Handler',
  handles => [qw(request asset_path html_head_tags)],
  default => sub {
    my $self = shift;
    my $class = $self->_resolve_handler_class($self->type);
    return $class->new({
      %{$self->_build_params},
      Controller => $self
    });
  }
);

# Delegate all other function calls to the Handler to support future
# Handler classes and new methods
our $AUTOLOAD;
sub AUTOLOAD {
  $AUTOLOAD =~ /([^:]+)$/;
  eval "sub $1 { (shift)->_Handler->$1(\@_); }";
  goto $_[0]->can($1);
}

sub _resolve_handler_class {
	my $self = shift;
  my $class = shift;
  
  # legacy, original, lower-case, built-in type names:
  my %type_aliases = ( css => 'CSS', js => 'JS', directory => 'Directory' );
  $class = $type_aliases{$class} if (exists $type_aliases{$class});
  
  # Allow absolute class names using '+' prefix:
  $class = $class =~ /^\+(.*)$/ ? $1 
    : "Catalyst::Controller::AutoAssets::Handler::$class";
	Module::Runtime::require_module($class);
	return $class;
}

sub BUILD {
  my $self = shift;
  
  # init type handler:
  $self->_Handler;
}

sub index :Chained :PathPrefix {
  my ($self, $c, @args) = @_;
  
  # New: set 'abort' just like Static::Simple to suppress log messages:
  if ( $self->no_logs && $c->log->can('abort') ) {
    $c->log->abort( 1 );
  }
  
  $self->request($c,@args);
  $c->detach;
}

sub unknown_asset {
  my ($self,$c,$asset) = @_;
  $asset ||= $c->req->path;
  $c->res->status(404);
  # Clear any other headers that might have been set, like Etag. We don't
  # want to allow negative caching
  $c->res->headers->clear;
  $c->res->header( 'Content-Type' => 'text/plain' );
  $c->res->body( "No such asset '$asset'" );
  return $c->detach;
}

1;

__END__

=pod

=head1 NAME

Catalyst::Controller::AutoAssets - Automatic asset serving via sha1-based URLs

=head1 SYNOPSIS

In your controller:

  package MyApp::Controller::Assets::MyCSS;
  use parent 'Catalyst::Controller::AutoAssets';
  
  1;

Then, in your .conf:

  <Controller::Assets::MyCSS>
    include   root/my_stylesheets/
    type      CSS
    minify    1
  </Controller::Assets::MyCSS>

And in your .tt files:

  <head>
    <link rel="stylesheet" type="text/css" href="[% c.controller('Assets::MyCSS').asset_path %]" />
  </head>

Or, to have the appropriate tags generated for you:

  <head>
    [% c.controller('Assets::MyCSS').html_head_tags %]
  </head>

Or, in static HTML:

  <head>
    <link rel="stylesheet" type="text/css" href="/assets/mycss/current.css" />
  </head>

=head1 PLUGIN INTERFACE

A Catalyst Plugin interface is also available for easy setup of multiple asset controllers at once. See

=over

=item L<Catalyst::Plugin::AutoAssets>

=back

=head1 DESCRIPTION

Fast, convenient and extendable serving of assets (CSS, JavaScript, Images, etc) at URL path(s) containing sha1 
checksums. This is an alternative/supplement to L<Catalyst::Plugin::Static::Simple> or
external/webserver for serving of an application's "nearly static" content.

The benefit of serving files through CAS paths ("content-addressable storage" - same design used by Git) 
is that it automatically alleviates client caching issues while simultaneously taking advantage of 
maximum aggressive HTTP cache settings. Because URL paths contain the sha1 checksum of the data, 
browsers can safely cache the content forever because "changes" automatically become new URLs. 
If the content (CSS, JavaScript or other) is modified later on, the client browsers instantly 
see the new version.

This is particularly useful when deploying new versions of an application where client browsers
out in the network might have cached CSS, JavaScript and Images from previous versions. Instead of asking 
users to hit "F5", everyone gets the new content automagically, with no intervention required (and no
sporadically broken user experiences when you forget to plan for cached data).
All you have to do is change the content; the module handles the rest.

This module also provides some optional extra features that are useful in both development and
production environments for automatically managing, minifying and deploying CSS, JavaScript, Image and Icon assets.

=head1 PERFORMANCE

Besides the performance benefits of aggressive HTTP caching (which can be significant, depending of the
ratio of first-time visitors to returning visitors) this module has also been optimized to serve requests
 as fast as possible. On typical requests, all that happens besides returning the content from
disk is one extra file stat and comparison of mtime. So, even with it's real-time content-change tracking and
checksums, this module is essentially identical to L<Catalyst::Plugin::Static::Simple> from a performance 
perspective (and may even be slightly faster because it caches guessed Content-Types instead of calculating on every
request like Static::Simple).

=head2 When to use this module

This module is great for development, web applications, and any production site with a high percentage of
returning users. If you want to take maximum advantage of HTTP caching without any work or planning, this module
is for you. Or, if you just want an easy and flexible way to manage static content, performance benefits aside,
this module is also for you.

=head2 When not to

The only cases where this module is not recommended is on very high-volume sites where most of the visits are
unique (i.e. little benefit from HTTP caching), or where the scale is large enough that the marginal
increase in speed of serving static content directly from the web server (like Apache), instead of through Catalyst,
is worth manually - and correctly - doing all the things that this module does automatically. Unless you are carefully
planning your HTTP caching strategy (such configuring Apache's cache settings) and coordinating all this with
content changes/new releases, this module is likely to outperform your manual setup.

=head1 HANDLERS

Note: All config params and methods described below are actually delegated to the type handler specified in 'type' and some are
specific (as noted below). For convenience, the core handlers C<Directory>, C<CSS> and C<JS> are documented below but others
are available (and custom handlers can also be written). To see other available type handlers and for information on writing 
custom handlers see:

=over

=item L<Catalyst::Controller::AutoAssets::Handler>

=back

=head1 CONFIG PARAMS

=head2 type

B<Required> - The asset type: C<Directory>, C<CSS>, C<JS>, etc.

The asset type is a "Handler" class name, and the core built in types are covered below. Custom handlers
can also be written. See L<Catalyst::Controller::AutoAssets::Handler> for details.

The C<Directory> asset type works in a similar manner as Static::Simple to make some directory
structure accessible at a public URL. The root of the structure is made available at the URL path:

  <CONTROLLER_PATH>/<SHA1>/

L<MIME::Types> is used to set the C<Content-Type> HTTP header based on
the file extension (same as Static::Simple does).

Because the sha1 checksum changes automatically and is unknown in advance, the above Asset Path is made available
via the C<asset_path()> controller method for use in TT files and throughout the application.

The C<CSS> and C<JS> types serve one automatically generated text file that is concatenated and
optionally minified from the include files. The single, generated file is made available at the URL 
Path:

  <CONTROLLER_PATH>/<SHA1>.js    # for 'JS' type
  <CONTROLLER_PATH>/<SHA1>.css   # for 'CSS' type

The js/css types provide a bonus mode of operation to provide a simple and convenient way to 
manage groups of CSS and JavaScript files to be automatically deployed in the application. This
is also particularly useful during development. Production applications with their own management
and build process for CSS and JavaScript would simply use the C<Directory> type.

=head2 no_logs

Defaults to true to suppress log messages in the same manner as Static::Simple.

=head2 include

B<Required> - String or ArrayRef. The path(s) on the local filesystem containing the source asset files. 
For C<Directory> type this must be exactly one directory, while for C<CSS> and C<JS> it can
be a list of directories or files. The C<include> directory becomes the root of the files hosted as-is
for the C<Directory> type, while for C<CSS> and C<JS> asset types it is the include files 
concatenated together (and possibly minified) to be served as the single file.

Source content can also be supplied directly in the form of a ScalarRef (as ScalarRef directly, or
included within the ArrayRef). This removes the need to have pre-existing file(s) on disk, 
which may useful/convenient for cases involving code-generated content. This only makes sense for
for concatenated asset types like C<CSS> and C<JS>, since there are no filenames to reference for 
the case of a C<Directory> asset.

=head2 include_regex

Optional regex ($string) to require files to match to be included.

=head2 exclude_regex

Optional regex ($string) to use to exclude files from the includes.

=head2 regex_ignore_case

Whether or not to use case-insensitive regex (qr/$regex/i vs qr/$regex/) when evaluating 
include_regex/exclude_regex.

Defaults to false (0).

=head2 current_redirect

Whether or not to make the current asset available via 307 redirect to the
real, current checksum/fingerprint asset path. This is a pure HTTP mechanism of resolving the
asset path.

  <CONTROLLER_PATH>/current/      # for 'directory' type
  <CONTROLLER_PATH>/current.js    # for 'js' type
  <CONTROLLER_PATH>/current.css   # for 'css' type

For instance, you might reference a CSS file from a C<Directory> asset C<Controller::Assets::ExtJS> 
using this URL path (i.e. href in an HTML C<link> tag):

  /assets/extjs/current/resources/css/ext-all.css

This path would redirect (HTTP 307) to the current asset/file path which would be something like:

  /assets/extjs/1512834162611db1fab246dfa87e3a37f68ed95f/resources/css/ext-all.css

The downside of this is that the server has to serve the non-cachable redirect every time, which 
partially defeats the performance benefits of this module (although the redirect is comparatively lightweight).

The other mechanism to find the current asset path is via the C<asset_path()> method, which returns
the current path outright and is the recommended usage, but is only available in locations where 
application controller methods can be called (like in TT files).

Defaults to true (1).

=head2 current_alias

Alias to use for the C<current_redirect>. Defaults to 'current' (which also implies 'current.js'/'current.css'
for C<JS> and C<CSS> asset types).

=head2 allow_static_requests

Whether or not to make the current asset available directly via a static path ('/static/'). This is like
current_redirect except the asset is served directly. This is essentially only useful for debug purposes
as it will make no use of caching.

See also 'use_etags' below.

Defaults to false (0).

=head2 current_response_headers

Extra headers to set in the response for 'current' requests. Cache-Control => 'no-cache' is always set unless
it is overridden here.

Defaults to empty HashRef {}

=head2 static_alias

Alias to use for static requests if C<allow_static_requests> is enabled. Defaults to 'static'.

=head2 static_response_headers

Extra headers to set in the response for 'static' requests. Cache-Control => 'no-cache' is always set unless
it is overridden here.

Defaults to empty HashRef {}

=head2 use_etags

Whether or not to set 'Etag' ("Entity Tag") HTTP response headers and check 'If-None-Match' client request headers to return
HTTP/304 'Not Modified' responses to clients that already have the current version of the requested asset/file.
This is essentially the same default behavior as Apache.

Etags provide another content-based mechanism (built into HTTP 1.1) for cache validation. This module accomplishes
even better cache validation than Etags because it avoids the validation request needed to check the current Etag in the first place,
however, Etag functionality has also been included because it is very useful when enabling and using 'static' paths which
do not make use of the checksum in the URL. Also, when Etags are present, most browsers will use them even when hitting 
"F5" to manually reload the page to avoid downloading the content again, so this feature further increases performance
for the F5 use-case which many users may be in the habit of doing for various legit reasons.

Defaults to false (0).

=head2 minify

Whether or not to attempt to minify content for C<CSS> or C<JS> asset types. This is a purely optional
convenience feature.

Defaults to false (0). Does not apply to the C<Directory> asset type.

=head2 minifier

CodeRef used to minify the content when C<minify> is true. The default code is a pass-through to 
C<CSS::Minifier::minify()> for C<CSS> assets and C<JavaScript::Minifier::minify()> for C<JS>. If
you want to override you must follow the same API as in those modules, using the C<input> and 
C<outfile> filehandle interface. See L<JavaScript::Minifier> and L<CSS::Minifier> for more details.

Does not apply to the C<Directory> asset type.

=head2 scopify

Applies only to the C<CSS> asset type. CSS will be scopified using L<CSS::Scopifier>. The scopify param
should be an ArrayRef that will be used to pass to argument list of the C<scopify> method. Note that
scopify and minify are net yet supported together. 

=head2 work_dir

The directory where asset-specific files are generated and stored. This contains the checksum/fingerprint 
file, the lock file, and the built file. In the case of C<Directory> assets the built file contains a manifest
of files and in the case of C<CSS> and C<JS> assets it contains the actual asset content (concatenated and 
possibly minified)

Defaults to:

  <APP_TMPDIR>/AutoAssets/<CONTROLLER_PATH>/

=head2 max_lock_wait

Number of seconds to wait to obtain an exclusive lock when recalculating/regenerating. For thread-safety, when the system
needs to regenerate the asset (fingerprint and built file) it obtains an exclusive lock on the lockfile in the 
work_dir. If another thread/process already has a lock, the system will wait for up to C<max_lock_wait> seconds
before proceeding anyway.

Note that this is only relevant when the source/include content changes while the app is running (which should never 
happen in a production environment).

Defaults to 120 seconds.

Also, see BUGS for caveats about locking.

=head2 max_fingerprint_calc_age

Max number of seconds before recalculating the fingerprint of the content (sha1 checksum)
regardless of whether or not the mtime has changed. 0 means infinite/disabled.

For performance, once the system has calculated the checksum of the asset content it caches the mtime
of the include file(s) and verifies on each request to see if they have changed. If they have, it 
regenerates the asset on the fly (recalculates the checksum and concatenates and minifies (if enabled)
for C<CSS> and C<JS> asset types). If C<max_fingerprint_calc_age> is set to a non-zero value, it will force the
system to regenerate at least every N seconds regardless of the mtime. This would only be needed in cases
where you are worried the content could change without changing the mtime which shouldn't be needed in
most cases.

Defaults to 0.

=head2 persist_state

For faster start-up, whether or not to persist and use state data (fingerprints and mtimes) across restarts to avoid 
rebuilding which may be expensive and unnecessary. The asset fingerprint is normally always recalculated at startup, but if this option
is enabled it is loaded from a cache/state file maintained on disk. This is useful for assets that take a long time
to build (such as big include libs) and is fine as long as you trust the state data stored on disk.

WARNING: Use this feature with caution for 'directory' type assets since the mtime check does not catch file content changes
alone (only filename changes), and when this is enabled it may not catch changes even across app restarts which may
not be expected.

No effect if max_fingerprint_calc_age is set.

Defaults to false (0).

=head2 asset_content_type

The content type returned in the 'Content-Type' header. Defaults to C<text/css> or C<text/javascript>
for the C<CSS> and C<JS> types respectively. 

Does not apply to C<Directory> asset type. For files within C<Directory> type assets, the Content-Type 
is set according to the file extension using L<MIME::Types>.

=head2 cache_control_header

The HTTP C<'Cache-Control'> header to return when serving assets. Defaults to the maximum 
aggressive value that should be honored by most browsers (1 year):

  public, max-age=31536000, s-max-age=31536000

=head2 sha1_string_length

Optional custom length (truncated) for the SHA1 fingerprint/checksum hex string. The full 40 characters is
probably overkill and so this option is provided if shorter URLs are desired. The lower the number the greater
the chance of collision, so you just need to balance the risk with how much you want shorter URLs (not that under normal
use cases these URLs need to be entered by a human in the first place). If you don't understand what this means then
just leave this setting alone.

Must be a integer between 5 and 40.

Defaults to 40 (full SHA1 hex string).

=head2 include_relative_dir

The directory to use to resolve relative paths in the C<include> param. Defaults to the Catalyst home directory.

=head1 METHODS

=head2 asset_path

Returns the current, public URL path to the asset:

  <CONTROLLER_PATH>/<SHA1>       # for 'Directory' type
  <CONTROLLER_PATH>/<SHA1>.js    # for 'JS' type
  <CONTROLLER_PATH>/<SHA1>.css   # for 'CSS' type

For C<Directory> asset types, accepts an optional subpath argument to a specific file. For example,
if there was a file C<images/logo.gif> within the include directory, $c->controller('Foo::MyAsset')->asset_path('images/logo.gif')
might return:

  /foo/myasset/1512834162611d99fab246dfa87345a37f68ed95f/images/logo.gif

=head2 html_head_tags

Convenience method to generate a set of tags, such as CSS <link> and JS <script>, suitable to drop 
into the <head> section of an HTML document. What this returns, if anything, is dependent on the asset
type.

=head1 BUGS/TODO

=over

=item Rebuilds assets on every request if they are empty (i.e. no files within the include_dir) FIXME

=item Newly added files within a subdirectory do not trigger a rebuild and cannot be accessed, even directly,
because it does not change the mtime of the top directory.
See 'all_dirs' option below for a possible fix for this problem. The other fix would be to always check the
file system for an exact subfile path, even if it does not exist in the subfile_meta data.

=item Needs an 'mtime_check_mode' option to be able to control how thorough the mtime check on every
request is. This mainly applies to Directory assets and could be tweaked according to the number of files.
Possible modes could be 'top_dir' (only check the mtime of the top directory, default for Directory), 
'all_dirs' (check all sub directories), 'all' (check all include files, default for CSS/JS) and 'none'
to turn off the real-time mtime checks entirely.

=item Needs a 'require_checksum' option to be able to require a specific asset fingerprint (such as for
included libs that should always have the same checksum, like the ExtJS 3.4.0 release, for instance)

=back

=head1 BUGS

The AutoAssets handler uses a lock file to prevent simultaneous builds on the
same resource.  This lock file is implemented with flock() and also setting
FD_CLOEXEC on the file handle, so there shouldn't be much danger of the lock
leaking to a child process, UNLESS your system doesn't support FD_CLOEXEC,
such as on Windows.  So, if you're on Windows and shell out during the
L<build_asset> method, and your external program hangs, the lock won't get
released until that program is killed, regardless of whether you restart
your web service.  (or, you can try to close all un-needed file descriptors
before exec()ing the external program, and avoid the problem, which is a
good policy anyway!)

=head1 SEE ALSO

=over

=item L<Catalyst::Plugin::AutoAssets>

=item L<Catalyst::Plugin::Assets>

=item L<Catalyst::Controller::VersionedURI>

=item L<Plack::Middleware::Assets>

=item L<Plack::Middleware::JSConcat>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

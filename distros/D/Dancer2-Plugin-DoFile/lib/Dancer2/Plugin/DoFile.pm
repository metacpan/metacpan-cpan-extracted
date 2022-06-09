package Dancer2::Plugin::DoFile;
$Dancer2::Plugin::DoFile::VERSION = '0.12';
# ABSTRACT: File-based MVC plugin for Dancer2

use strict;
use warnings;

use Dancer2::Plugin;

use JSON;
use Hash::Merge;

has page_loc => (
    is      => 'rw',
    default => sub {'dofiles/pages'},
);

has default_file => (
    is      => 'rw',
    default => sub {'index'},
);

has extension_list => (
    is      => 'rw',
    default => sub { ['.do', '.view']}
);

plugin_keywords 'dofile';

my %dofiles;

sub BUILD {
    my $self     = shift;
    my $settings = $self->config;

    $settings->{$_} and $self->$_( $settings->{$_} )
      for qw/ page_loc default_file extension_list /;
}

sub dofile {
  my $plugin = shift;
  my $arg = shift;
  my %opts = @_;

  my $app = $plugin->app;
  my $settings = $app->settings;
  my $method = $app->request->method;
  my $pageroot = $settings->{appdir};
  if ($pageroot !~ /\/$/) {
    $pageroot .= "/";
  }
  $pageroot .= $plugin->page_loc;

  my $path = $arg || $app->request->path;

  # If any one of these returns content then we stop processing any more of them
  # Content is defined as an array ref (it's an Obj2HTML array), a hashref with a "content" element, or a scalar (assumed HTML string - it's not checked!)
  # This can lead to some interesting results if someone doesn't explicitly return undef when they want to fall through to the next file
  # as perl will return the last evaluated value, which would be intepretted as content according to the above rules

  my $merger = Hash::Merge->new('RIGHT_PRECEDENT');

  my $stash = $opts{stash} || {};

  # Safety first...
  $path =~ s|/$|"/".$plugin->default_file|e;
  $path =~ s|^/+||;
  $path =~ s|\.\./||g;
  $path =~ s|~||g;

  if (!$path) { $path = $plugin->default_file; }
  if (-d $pageroot."/$path") {
    if ($path =~ /\/$/) {
      $path .= "/".$plugin->default_file;
    } else {
      return {
        url => "/$path/",
        redirect => 1,
        done => 1
      };
    }
  }

OUTER:
  foreach my $ext (@{$plugin->extension_list}) {
    foreach my $m ("", "-$method") {
      my $cururl = $path;
      my @path = ();

      # This iterates back through the path to find the closest FILE downstream, using the rest of the url as a "path" argument
      while (!-f $pageroot."/".$cururl.$m.$ext && $cururl =~ s/\/([^\/]*)$//) {
        if ($1) { unshift(@path, $1); }
      }

      # "Do" the file
      if ($cururl) {
        my $result;
        if (defined $dofiles{$pageroot."/".$cururl.$m.$ext}) {
          $result = $dofiles{$pageroot."/".$cururl.$m.$ext}->({path => \@path, this_url => $cururl, dofile_plugin => $plugin, stash => $stash, env => $app->request->env});

        } elsif (-f $pageroot."/".$cururl.$m.$ext) {
          our $args = { path => \@path, this_url => $cururl, dofile_plugin => $plugin, stash => $stash, env => $app->request->env };

          $result = do($pageroot."/".$cururl.$m.$ext);
          if ($@ || $!) { $plugin->app->log( error => "Error processing $pageroot / $cururl.$m.$ext: $@ $!\n"); }
          if (ref $result eq "CODE") {
            $dofiles{$pageroot."/".$cururl.$m.$ext} = $result;
            $result = $result->($args);
          }
        }

        if (defined $result && ref $result eq "HASH") {
          if (defined $result->{url} && !defined $result->{done}) {
            $path = $result->{url};
            next OUTER;
          }
          if (defined $result->{content} || $result->{url} || $result->{done}) {
            return $result;
          } else {
            $stash = $merger->merge($stash, $result);
          }
          # Move on to the next file

        } elsif (ref $result eq "ARRAY") {
          return { content => $result };

        } elsif (!ref $result && $result) {
          # do we assume this is HTML? Or a file to use in templating? Who knows!
          return { content => $result };

        }
      }
    }
  }

  # If we got here we didn't find a do file that returned some content
  return { status => 404 };
}

sub view_pathname {
  my ( $self, $view ) = @_;
  return path($view);
}
sub layout_pathname {
  my ( $self, $layout ) = @_;
  return $layout;
}

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::DoFile - A file based MVC style plugin for Dancer2

=head1 SYNOPSYS

In your config.yml

    plugins:
      DoFile:
        page_loc: "dofiles/pages"
        default_file: "index"
        extension_list: ['.do','.view']

Make sure you have created the directory used for page_loc

Within a route in dancer2:

    my $result = dofile 'path/to/file'

You must not include the extension of the file as part of the path, as this will
be added per the settings.

Or a default route, with example handling of some return values:

    prefix '/';
    any qr{.*} => sub {
      my $self = shift;
      my $result = dofile undef;
      if ($result && ref $result eq "HASH") {
        if (defined $result->{status}) {
          status $result->{status};
        }
        if (defined $result->{url}) {
          if (defined $result->{redirect} && $result->{redirect} eq "forward") {
            return forward $result->{url};
          } else {
            return redirect $result->{url};
          }
        } elsif (defined $result->{content}) {
          return $result->{content};
        }
      }
    };

When the 1st parameter to 'dofile' is undef it'll use the request URI to work
out what the file(s) to execute are.

=head1 DESCRIPTION

DoFile is a way of automatically pulling multiple perl files to execute as a way
to simplify routing complexity in Dancer2 for very large applications. In
particular it was designed to offload "as many as possible" URIs that related to
some standard functionality through a default route, just by having files
existing for the specific URI.

The magic will look through your filesystem for files to 'do' (execute), and
there may be several. The intent is to split out controller files and
view files, and these may individually be rolled out or split out. In the
default configuration the controller files are suffixed .do, and the view files
.view

=head2 File Search Ordering

When presented with the URI C<path/to/file> DoFile will begin searching for
files that can be executed for this request, until it finds one that returns
something that looks like content, a URL or is told you're done, when it stops.

Files are searched:

=over 4

=item * By extension

The default extensions .do and .view are checked, unless defined in your
config.yml. The intention here is that .do files contain controller code and
don't typically return content, but may return redirects. After .do files have
been executed, .view files are executed. These are expected to return content.

You can define as many extensions as you like. You could, for example have:
C<['.init','.do','.view','.final']>

=item * Root/HTTP request method

For each extension, first the "root" file C<file.ext> is tested, then a file
that matches C<file-METHOD.ext> is tested (where METHOD is the HTTP request
method for this request, .ext is the extension).

=item * Iterating up the directory tree

If your call to C<path/to/file> results in a miss for C<path/to/file.do>, DoFile
will then test for C<path/to.do> and finally C<path.do> before moving on to
C<path/to/file-METHOD.do>

Once DoFile has found one it will not transcend the directory tree any further.
Therefore defining C<path/to/file.do> and C<path/to.do> will not result in
both being executed for the URI C<path/to/file> - only the first will be
executed.

=back

If you define files like so:

    path.do
    path/
      to.view
      to/
        file-POST.do

A POST to the URI C<path/to/file> will execute C<path.do>, then
C<path/to/file-POST.do> and finally C<path/to.view>.

=head2 Arguments to the executed files

During execution of the file a hashref called $args is available that contains
some important things.

If the executed file returns a coderef, the coderef is executed with this same
hashref as the only argument.

=over 4

=item * path (arrayref)

Anything that appears after the currently executing file on the URI. For example
if I request C</path/to/file> and DoFile is executing C<path-POST.do>, the
C<path> element will contain ['to','file']

=item * this_url (string)

The currently executing file without any extension. In the above example this
would be C<path>.

=item * stash (hashref)

The stash can be initially passed from the router:

    dofile 'path/to/file', stash => { option => 1 }

The stash can be read/written to from each file that executes:

    if ($args->{stash}->{option} == 1) {
      $args->{stash}->{anotheroption} = 2;
    }

Or if the file being executed returns a hashref that does not contain any of
the elements C<contents>, C<url> or C<done> (see below), it's merged into the
stash automatically for passing on to the next file to be executed

The stash is used to pass internal state down the file chain.

=item * dofile_plugin (object)

Just in case the file being executed wants to mess about with Dancer2 or
the plugin's internals.

=back

=head2 How DoFile interprets individual executed files response

The result (returned value) of each file is checked; if something is returned
DoFile will inspect the value to determine what to do next.

=head3 Coderef (anonymous sub)

You can return a coderef; this will be cached within the plugin and the file
will not be checked again, but the coderef will be executed each time that
"file" is requested. Generally whether the file should be checked or not is
left up to the application (e.g. C<plackup -R ./ -r ...>).

In the case a coderef is used, when the code is executed it is passed one
argument, a hashref, which is the stash. This saves needing to import the stash
from within the code of the file.

The return of the coderef will be evaluated exactly as below.

=head3 Internal Redirects

If a hashref is returned it's checked for a C<url> element but NO C<done>
element. In this case, the DoFile restarts from the begining using the new URL.
This is a method for internally redirecting. For example, returning:

    {
      url => "account/login"
    }

Will cause DoFile to start over with the new URI C<account/login>, without
processing any more files from the old URI. The stash is preserved.

=head3 Content

If a scalar or arrayref is returned, it's wrapped into a hashref into the
C<contents> element and sent back to the router.

If a hashref is returned and contains a C<contents> element, no more files will
be processed. The entire hashref is returned to the router. NB: the
C<contents> element must contain something that evals to true, else it's
considered not there.

=head3 Done

If a hashref is returned and there is a C<done> element that evals to a true
value, DoFile will stop processing files and return the returned hashref to
the router.

=head3 Continue

If a hashref is returned and there is no C<url>, C<content> or C<done> element
then the contents of the hasref is combined with the stash and DoFile will look
for the next file.

If nothing is returned at all, DoFile will continue with the next file.

=head2 What the router gets back

DoFile will always return a hashref, even if the files being executed do not
return a hashref. This hashref may have anything, but the recommended design
is to return one of the following:

=over 4

=item * A C<contents> element

The implication is that you've had the web page to be served back. Note that
DoFile doesn't care if this is a scalar string or an arrayref. This Plugin
was designed to work with Obj2HTML, so in the case of an arrayref the
implication is that Obj2HTML should be asked to convert that to HTML.

=item * A C<url> element

In this case the router should probably send a 30x response redirecting the
client, or perform an internal forward... implementors choice.

=item * A C<status> element

This could be used to set the status code for returning to the client

=back

DoFile may however return pretty much whatever you want to handle in your final
router code.

=head1 EXAMPLES

As noted, what's returned from a DoFile can contain anything. That gives you
the opportunity to do pretty much whatever you want with what's returned.


=head1 AUTHOR

Pero Moretti

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Pero Moretti.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

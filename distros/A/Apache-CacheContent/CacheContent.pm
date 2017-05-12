package Apache::CacheContent;

use strict;

$Apache::CacheContent::VERSION = '0.12';
@Apache::CacheContent::ISA = qw(Apache);

use Apache;
use Apache::Constants qw(OK SERVER_ERROR DECLINED);
use Apache::File ();
use Apache::Log ();

sub disk_cache ($$) {
  my ($self, $r) = @_;

  my $log  = $r->server->log;
  my $file = $r->filename;

  # Convert configured minutes to days for -M test.
  my $timeout = $self->ttl($r) / (24*60);

  # Test age of file.
  if (-f $r->finfo && -M _ < $timeout) {
    $log->info("using cache file '$file'");
    return DECLINED;
  }

  # No old file to use, so make a new one.
  $log->info("generating '$file'");

  # First, create a request object from our Capture class below.
  my $fake_r = Apache::CacheContent::Capture->new($r);

  # Call the handler() subroutine of the subclass,
  # but pass it the fake $r so that we get the content back.
  $self->handler($fake_r);

  # Now, write the content from handler() to a file on disk.
  my $fh = Apache::File->new(">$file");

  unless ($fh) {
    $log->error("Cannot open '$file': $!");
    return SERVER_ERROR;
  }

  # Dump the content.
  print $fh $fake_r->data();

  # We need to call close() explicitly here or else
  # the Content-Length header does not get set properly.
  $fh->close;

  # Finally, reset the filename to point to the newly
  # generated file and let Apache's default handler send it.
  $r->filename($file);

  return OK;
}

sub ttl {
  # Get the cache time in minutes.
  # Default to 1 hour.

  return shift->dir_config('CacheTTL') || 60;
}

sub handler {

  my ($self, $r) = @_;

  $r->send_http_header('text/html'); # ignored...

  $r->print(" --- non-subclassed request --- ");
}

# Package that capture's handler output and stash it away.

package Apache::CacheContent::Capture;

@Apache::CacheContent::Capture::ISA = qw(Apache);

sub new {
  my ($class, $r) = @_;

  $r ||= Apache->request;

  tie *STDOUT, $class, $r;

  return tied *STDOUT;
}

sub print {
  # Intercept print so we can stash the data.

  shift->{_data} .= join('', @_);
}

sub data {
  # Return stashed data.

  return shift->{_data};
}

sub send_http_header {
  # no-op - don't send headers from a PerlFixupHandler.
};

# Capture regular print statements.

sub TIEHANDLE {
  my ($class, $r) = @_;

  return bless { _r    => $r,
                 _data => undef
  }, $class;
}

sub PRINT {
  shift->print(@_);
}

1;

__END__

=head1 NAME

Apache::CacheContent - PerlFixupHandler class that caches dynamic content

=head1 SYNOPSIS

=over 4

=item * Make your method handler a subclass of Apache::CacheContent

=item * allow your web server process to write into portions of your
      document root.

=item * Add a ttl() subroutine (optional)

=item * Add directives to your F<httpd.conf> that are similar to these:

=back

  PerlModule MyHandler

  # dynamic url
  <Location /dynamic>
    SetHandler perl-script
    PerlHandler MyHandler->handler
  </Location>

  # cached URL
  <Location /cached>
    SetHandler perl-script
    PerlFixupHandler MyHandler->disk_cache
    PerlSetVar CacheTTL 120   # in minutes...
  </Location>


=head1 DESCRIPTION

=over 15

=item Note:

This code is derived from the I<Cookbook::CacheContent> module,
available as part of "The mod_perl Developer's Cookbook"

=for html (see <a href="http://www.modperlcookbook.org">http://www.modperlcookbook.org</a>)

=back

The Apache::CacheContent module implements a PerlFixupHandler that
helps you to write handlers that can automatically cache generated web
pages to disk.  This is a definite performance win for sites that end
up generating the exact same content for many users.

The module is written to use Apache's built-in file handling routines
to efficiently serve data to clients.  This means that your code will
not need to worry about HTTP/1.X, byte ranges, if-modified-since, HEAD
requests, etc.  It works by writing files into your DocumentRoot, so
be sure that your web server process can write there.

To use this you MUST use mod_perl method handlers.  This means that
your version of mod_perl must support method handlers (the argument
EVERYTHING=1 to the mod_perl build will do this).  Next you'll need to
have a content-generating mod_perl handler.  If isn't a method handler
modify the I<handler> subroutine to read:

  sub handler ($$) {
    my ($class, $r) = @_;
    ....

Next, make your handler a subclass of I<Apache::CacheContent> by
adding an ISA entry:

  @MyHandler::ISA = qw(Apache::CacheContent);

You may need to modify your handler code to only look at the I<uri> of
the request.  Remember, the cached content is independent of any query
string or form elements.

After this is done, you can activate your handler.  To use your
handler in a fully dyamic way configure it as a PerlHandler in your
F<httpd.conf>, like this:

  PerlModule MyHandler
  <Location /dynamic>
    SetHandler perl-script
    PerlHandler MyHandler->handler
  </Location>

So requests to I<http://localhost/dynamic/foo.html> will call your
handler method directly.  This is great for debugging and testing the
module.  To activate the caching mechanism configure F<httpd.conf> as
follows:

  PerlModule MyHandler
  <Location /cached>
    SetHandler perl-script
    PerlFixupHandler MyHandler->disk_cache
    PerlSetVar CacheTTL 120  # in minutes..
  </Location>

Now when you access URLs like I<http://localhost/cached/foo.html> the
content will be generated and stored in the file
F<I<DocumentRoot>/cached/foo.html>.  Subsequent request for the same
URL will return the cached content, depending on the I<CacheTTL> setting.

For further customization you can write your own I<ttl> function that
can dynamically change the caching time based on the current request.


=head1 AUTHORS

Paul Lindner E<lt>paul@modperlcookbook.orgE<gt>

Geoffrey Young E<lt>geoff@modperlcookbook.orgE<gt>

Randy Kobes E<lt>randy@modperlcookbook.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2001, Paul Lindner, Geoffrey Young, Randy Kobes.

All rights reserved.

This module is free software.  It may be used, redistributed
and/or modified under the same terms as Perl itself.

=head1 SEE ALSO

The example mod_perl method handler C<CacheWeather>.

The mod_perl Developer's Cookbook

=for html <A href="http://www.modperlcookbook.org">http://www.modperlcookbook.org</a>

=head1 HISTORY

This code is derived from the I<Cookbook::CacheContent> module,
available as part of "The mod_perl Developer's Cookbook".

For more information, visit 

  http://www.modperlcookbook.org/

=cut


=cut

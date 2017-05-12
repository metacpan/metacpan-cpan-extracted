package Apache::Stage;
use Apache::Constants qw(DECLINED);
use strict;
use vars qw($VERSION $STAGE_REGEX $DEBUG);

$VERSION = '1.20';
$DEBUG = 0;

sub handler {
  my($r) = @_;

  my($redir,$chimp,$subr,$subret);
  $STAGE_REGEX ||= $r->dir_config("apache_stage_regex") ||
      q{ ^ (/STAGE/[^/]*) (.*) $ };
  ($chimp, $redir) = $r->prev->uri =~ m| $STAGE_REGEX |ox;
  return DECLINED unless length($redir);

  # Try it
  $subr = $r->lookup_uri($redir);
  $subret = $subr->run;

  # Propagate error or success code
  $r->status($subret);

  # Handle 301/2. That often indicates a forgotten trailing slash.
  if ($subret == 301 or $subret == 302) {

    # Read Location
    $redir = $subr->header_out("Location");

    # Rewrite Location
    require URI::URL;
    my $uri = URI::URL->new($redir);
    $uri->path($chimp . $uri->path);
    $r->header_out("Location",$uri->abs->as_string);

    # Header out leads to immediate rerequest by browser
    $r->send_http_header;
  }

  $r->log_error("redir[$redir] chimp[$chimp] subr[$subr] subret[$subret]")
      if $DEBUG;
}

1;

=head1 NAME

Apache::Stage - Manage A Staging Directory

=head1 SYNOPSIS

  <Location /STAGE>
    # this location is served by normal apache. It's recommended to
    # restrict access to this location to registered authors of this
    # site, but a restriction isn't necessary
    ErrorDocument 403 /stage-redir
    ErrorDocument 404 /stage-redir
  </Location>

  <Location /stage-redir>
    # the name of this location must match the ErrorDocument redirects
    # above

    # PerlSetVar apache_stage_regex " ^ (/STAGE/[^/]*) (.*) $ "

    # This regex has to split a staged URI into two parts. It is
    # evaluated with the /ox switch in effect, so this will NOT be a
    # per-directory variable. The first part will be thrown away and
    # just the second part will be served if the original URI cannot
    # be accessed. In case of 301 and 302 redirects the first part
    # will be prepended again. The default regex is defined as above
    # which means that URIS will be split into "/STAGE/anyuser" and
    # the rest.

    SetHandler perl-script
    PerlHandler Apache::Stage
    Options ExecCGI

  </Location>

=head1 DESCRIPTION

A staging place is a place where an author of an HTML document checks
the look and feel of a document before it's uploaded to the final
location. A staging place doesn't need to be a separate server, nor
need it be a mirror of the "real" tree, and not even a tree of
symbolic links. A sparse directory tree that holds nothing but the
staged files will do.

Apache::Stage implements a staging directory that needs a minimum of space.
Per default the path for the per-user staging directory is hardcoded as

  /STAGE/any-user-name

The code cares for proper internal and external redirects for any
documents that are not in the stage directory tree. This means that
all graphics are displayed as they will be later after the staged
files will have been published. The following table describes what has
been tested:

 Location              Redirect to       Comment

 /STAGE/u1/            /                 Homepage. Internal Redirect.

 /STAGE/u2/dir1        /dir1/            Really /dir1/index.html

 /STAGE/u3/dir2        /dir2/            Directory has no index.html
                                         Options Indexes is off, thus
                                         "Forbidden"

 /STAGE/u4/dir2/foo    /dir2/foo         Internal redirect.

 /STAGE/u5/bar         -                 Exists really, no redirect
                                         necessary

 /STAGE/u6             -                 Fails unless location exists

The entries described in SYNOPSIS in the access.conf or an equivalent
place define the name of the staging directory, the name of an
internal location that catches the exception when a document is not in
the staging directory, and the regular expression that transforms the
staging URI into the corresponding public URI.

With this setup only ErrorDocument 403 and 404 will be served by
Apache::Stage. If you need coexistence with different ErrorDocument
handlers, you will either have to disable them for /STAGE or integrate
the code of Apache::Stage into an if/else branch based on the path.

=head1 HISTORY

This module has not changed since 1997.

=head1 AUTHOR

andreas.koenig@anima.de

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

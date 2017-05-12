#! /usr/bin/perl 

=head1 NAME

Apache::AliasList - Apache translation handler to process lists of aliases

=head1 SYNOPSIS

In F<httpd.conf>:

 PerlTransHandler Apache::AliasList
 PerlSetVar AliasList /path/to/alias.list

In F<alias.list>:

 # Comment lines ignored
 /alias   /full/uri/spec.html

If http://domain/alias is requested, the document at
http://domain/full/uri/spec.html will be delivered.

=head1 DESCRIPTION

When using a content management system, it is common for URIs to become
quite long and complex. In many cases it is therefore desirable to provide
a shorter, more descriptive URI (e.g. to convey verbally or in print).

Apache provides an C<Alias> directive which can be used to make these
translations in the F<httpd.conf> configuration file. This approach however
has the disadvantage that a server restart is required for any changes to
take effect. Apache::AliasList removes this requirement by moving the alias
definitions into a separate file which can be updated without restarting
the server.

When an incoming request matches one of the listed aliases, an internal
redirect is performed - this keeps the original URI in the location bar
of the user's browser. 

If the incoming request matches the target of any defined aliases, 
Apache::AliasList will issue an HTTP status 302 response to redirect the
client to the source URI of the alias. This has the effect of changing
the URI shown in the client browser's location bar

=head2 Configuration

Create an F<alias.list> file:

 # Comments start with '#'
 /old_uri  /location/to/be/redirected/to
 /test     http://can.redirect.to/external/sites

Add the following directives to F<httpd.conf>:

 PerlTransHandler Apache::AliasList
 PerlSetVar AliasList /full/path/to/alias.list

=head2 Example

There is an alias between the pages http://perl.jonallen.info/modules
and http://perl.jonallen.info/bin/view/Main/PerlModules.

Accessing the URI http://perl.jonallen.info/modules will trigger the
internal redirect. The address shown in the browser does not change, but
the content returned is from the longer URI.

Requesting the page http://perl.jonallen.info/bin/view/Main/PerlModules
causes the external redirect to be issued, taking the client to 
http://perl.jonallen.info/modules. This URI will then be processed as 
described above.

=head1 TODO

Extend the reverse map feature to act as a content filter, substituting
URI links with their aliases in the returned HTML document.

=head1 AUTHOR

Written by Jon Allen (JJ) <jj@jonallen.info>

=head1 COPYRIGHT

Copyright (C) 2004 Jon Allen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

http://perl.jonallen.info

=cut

package Apache::AliasList;

use strict;
use warnings;
use Apache::Constants qw(:common REDIRECT);
use File::stat;

our $VERSION     = '0.08';
our $list_mtime  = 0;
our @aliaslist   = ();
our %forward_map = ();
our %reverse_map = ();

sub handler {
  my $r       = shift;
  my $handler = $r->current_callback;
  DISPATCH: {
    if ($handler eq 'PerlTransHandler') {return &PerlTransHandler($r,@_)}
    return DECLINED;
  }
}

sub PerlTransHandler {
  my $r     = shift;
  return DECLINED unless ($r->is_initial_req);
  
  (my $uri  = $r->uri) =~ s!([^/]+)/+$!$1!;
  
  # Reload the alias.list file if it has been modified since the last reload
  my $aliasfile = $r->dir_config('AliasList') or return DECLINED;
  my $st        = stat($aliasfile);
  if ($st->mtime > $list_mtime) {
    $list_mtime  = $st->mtime;
    @aliaslist   = &load_alias_list($r);
    %forward_map = &generate_forward_map(@aliaslist);
    %reverse_map = &generate_reverse_map(@aliaslist);
  }
  
  if ($forward_map{$uri}) {
    $uri = $forward_map{$uri};
    # Send a Redirect message if the new URI is a full (http://...)
    # address, otherwise just change the URI to redirect internally
    if ($uri =~ m!^[a-zA-Z]+://!) {
      $r->content_type('text/html');
      $r->header_out(Location => $uri);
      return REDIRECT;
    } else {
      $r->uri($uri);
      return DECLINED;
    }
  }

  if ($reverse_map{$uri}) {
    $uri = $reverse_map{$uri};
    $r->content_type('text/html');
    $r->header_out(Location => $uri);
    return REDIRECT;
  }

  return DECLINED;
}

sub load_alias_list {
  my $r         = shift;
  my $aliaslist = $r->dir_config('AliasList');
  open ALIASLIST,"< $aliaslist";
  my @list = (<ALIASLIST>);
  close ALIASLIST;
  return @list;
}

sub generate_forward_map {
  my %map = ();
  foreach (@_) {
    s/#.*//;  # Remove comments
    if (/^\s*(\S+)\s+(\S+)/) {
      $map{$1} = $2;
    }
  }
  return %map;
}

sub generate_reverse_map {
  my %map = ();
  foreach (@_) {
    s/#.*//;  # Remove comments
    if (/^\s*(\S+)\s+(\S+)/) {
      $map{$2} = $1;
    }
  }
  return %map;
}

1;

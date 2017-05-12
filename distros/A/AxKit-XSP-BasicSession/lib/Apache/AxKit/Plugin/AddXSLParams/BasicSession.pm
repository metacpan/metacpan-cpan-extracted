package Apache::AxKit::Plugin::AddXSLParams::BasicSession;
# $Id: BasicSession.pm,v 1.5 2004/09/17 02:05:22 kjetil Exp $

use strict;
use Apache::Constants;
use Apache::Cookie;
use Apache::Request;
use Apache::URI;
use vars qw($VERSION);
$VERSION = '0.20';


sub handler {
    my $r = shift;
    my $uri = $r->uri;
    my $cgi = Apache::Request->instance($r);
     
    return OK unless ($Apache::AxKit::Plugin::BasicSession::session{_session_id});
    $cgi->parms->set('session.id' => $Apache::AxKit::Plugin::BasicSession::session{_session_id});
    my $session = \%Apache::AxKit::Plugin::BasicSession::session;
    foreach my $sesskey ( keys( %{$session} ) ) {
        next if ($sesskey =~ /^_/);
        $cgi->parms->set('session.keys.' . $sesskey => $session->{$sesskey} );
    }  
       
    return OK;
}

1;
__END__

=head1 NAME

Apache::AxKit::Plugin::AddXSLParams::BasicSession - Provides a way to pass info from the BasicSession taglib to XSLT params

=head1 SYNOPSIS

  # in httpd.conf or .htaccess, but *AFTER* you load the BasicSession plugin.
  AxAddPlugin Apache::AxKit::Plugin::BasicSession
  AxAddPlugin Apache::AxKit::Plugin::AddXSLParams::BasicSession

=head1 DESCRIPTION

Apache::AxKit::Plugin::AddXSLParams::BasicSession (Whew! that's a
mouthful) offers a way to make information about the current session
available as params within XSLT stylesheets.  This module, as well as
parts of the documentation, were blatantly ripped off from
Apache::AxKit::Plugin::AddXSLParams::Request.  Thanks!

=head1 CONFIGURATION

There is no configuration for this module, seeing as all session
configuration needs to occur for the
Apache::AxKit::Plugin::BasicSession module.

=head1 USAGE

Like A:A:P:A:Request, you can access session key values by defining a
specially named XSL parameter.  A:A:P:A:BasicSession uses the prefix
"session.keys" to represent key values.  For instance, if you have a
session key named "search-max", the following would work:

  <xsl:param name="session.keys.search-max"/>
  ...
  <xsl:value-of select="$session.keys.search-max"/>

Any key that begins with an underscore ("_") will not be passed as an
XSL parameter, since these are considered "hidden" keys managed by the
BasicSession package.

In addition to the session keys, you can also get the session ID
string using C<session.id>.

=head1 DEPENDENCIES

=over 4

=item * AxKit::XSP::BasicSession

=item * AxKit (1.6 or greater)

=back

=head1 AUTHOR

Michael A Nachbaur, mike@nachbaur.com
Kjetil Kjernsmo, kjetilk@cpan.org

=head1 COPYRIGHT

Copyright (c) 2001-2004 Michael A Nachbaur, Kjetil Kjernsmo 2004. All
rights reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<AxKit>, L<AxKit::XSP::BasicSession>, L<Apache::AxKit::Plugin::BasicSession>

=cut

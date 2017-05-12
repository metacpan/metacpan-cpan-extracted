package Apache::AxKit::Plugin::BasicSession;
# $Id: BasicSession.pm,v 1.14 2004/09/16 23:20:43 nachbaur Exp $

use Apache::Session::Flex;
use Apache::Request;
use Apache::Cookie;
use Apache::AuthCookie;
use AxKit;
use vars qw( $VERSION %session );

$VERSION = 0.22;

sub handler
{
    my $r = Apache::Request->instance(shift);

    # Session handling code
    untie %session if (ref tied %session);
    my $no_cookie = 0;
    my $opts = {};

    $AxKit::XSP::Core::SessionCreator = \&AxKit::XSP::BasicSession::create;

    #
    # Fetch authentication name for this realm, or use the default 'BasicSession'
    # if the user hasn't set this up for handling authentication (e.g. basic session-
    # handling code)
    my $prefix = $r->auth_name || 'BasicSession';

    my %flex_options = (
        Store     => $r->dir_config( $prefix . 'DataStore' ) || 'DB_File',
        Lock      => $r->dir_config( $prefix . 'Lock' ) || 'Null',
        Generate  => $r->dir_config( $prefix . 'Generate' ) || 'MD5',
        Serialize => $r->dir_config( $prefix . 'Serialize' ) || 'Storable'
    );
    my $uri_token = $r->dir_config( $prefix . 'URIToken' ) || undef;

    #
    # Load session-type specific parameters, comma-separated, name => value pairs
    foreach my $arg ( split( /\s*,\s*/, $r->dir_config( $prefix . 'Args' ) ) )
    {
        my ($key, $value) = split( /\s*=>\s*/, $arg );
        $flex_options{$key} = $value;
    }

    my $sessionid = undef;
    if (defined $uri_token and length($uri_token) > 0) {
        $sessionid = $r->param($uri_token);
    }

    my $cookie_exists = 0;
    my $cookie_name = $r->dir_config($prefix . 'Cookie') ? $r->dir_config($prefix . 'Cookie') : 'SID';
    unless (defined $sessionid) {
        #
        # Read in the cookie if this is an old session, using this realm's name as part
        # of the cookie
        my $cookie = $r->header_in('Cookie');
        #my ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);
        ($sessionid) = $cookie =~ /$cookie_name=(\w*)/;
        $cookie_exists = defined($sessionid) ? 1 : 0;
    }

    #
    # Attempt to load the session from our back-end datastore
    eval { tie %session, 'Apache::Session::Flex', $sessionid, \%flex_options }
        if ($sessionid and $sessionid ne '');
    unless ( $session{_session_id} ) {
        AxKit::Debug(6, "Creating a new session, since \"$session{_session_id}\" didn't work.");

        eval { tie %session, 'Apache::Session::Flex', undef, \%flex_options };
        die "Problem creating session: $@" if $@;
        $no_cookie = 1;
    }

    # Might be a new session, so lets give them a cookie
    my $current_time = time;
    if (!$cookie_exists or $no_cookie) {
        #Apache::AuthCookie->send_cookie($session{_session_id});
        my %cookie_args = ();
        $cookie_args{'-name'} = $cookie_name;
        $cookie_args{'-value'} = $session{_session_id};
        $cookie_args{'-expires'} = $r->dir_config($prefix . 'CookieExpires');
        $cookie_args{'-domain'} = $r->dir_config($prefix . 'CookieDomain');
        $cookie_args{'-path'} = $r->dir_config($prefix . 'CookiePath');
        Apache::Cookie->new($r, %cookie_args)->bake;

        $session{_creation_time} = $current_time;
        AxKit::Debug(9, "Set a new header for the session cookie: \"$session_cookie\"");
    }

    # Update the "Last Accessed" timestamp key
    $session{_last_accessed_time} = $current_time;

    AxKit::Debug(9, "Successfully set the session object in the pnotes table");

    $r->push_handlers(PerlCleanupHandler => \&cleanup);
    return OK;
}

sub cleanup {
    my $r = shift;
    untie %session;
}

1;

__END__

=head1 NAME

Apache::AxKit::Plugin::BasicSession - AxKit plugin that handles setting / loading of Sessions

=head1 SYNOPSIS

    AxAddPlugin Apache::AxKit::Plugin::BasicSession
    AxAddPlugin Apache::AxKit::Plugin::AddXSLParams::BasicSession
    PerlSetVar BasicSessionDataStore "File"
    PerlSetVar BasicSessionArgs "Directory => /tmp/session"

=head1 DESCRIPTION

BasicSession is an AxKit plugin which automatically creates and manages
server-side user sessions.  Based on Apache::Session::Flex, this allows
you to specify all the parameters normally configurable through A:S::Flex.

B<NOTE>: If used in conjunction with the provided AxKit::XSP::BasicAuth module, the
following parameter's names should be changed to reflect your local realm
name.  For instance, "BasicSessionDataStore" should be changed to say
"RealmNameDataStore".  This allows for different configuration parameters
to be given to each realm in your site.

=head1 Parameter Reference

=head2 C<BasicSessionDataStore>

Sets the backend datastore module.  Default: DB_File

=head2 C<BasicSessionLock>

Sets the record locking module.  Default: Null

=head2 C<BasicSessionGenerate>

Sets the session id generation module.  Default: MD5

=head2 C<BasicSessionSerialize>

Sets the hash serializer module.  Default: Storable

=head2 C<BasicSessionArgs>

Comma-separated list of name/value pairs.  This is used to pass additional
parameters to Apache::Session::Flex for the particular modules you select.
For instance: if you use MySQL for your DataStore, you need to pass the
database connection information.  You could pass this by calling:

    PerlSetVar BasicSessionArgs "DataSource => dbi:mysql:sessions, \
                                 UserName   => session_user, \
                                 Password   => session_password"

=head2 C<BasicSessionURIToken>

While BasicSession defaults to using a cookie for sessions, there are times
(e.g. when performing C<document()> lookups within XSLT stylesheets) when it
is not possible to supply the proper cookie information with an HTTP request.

Therefore, you can use this configuration variable to set the name of a
query parameter where the session ID can be found.  This is not required, but
will be used in preference to a cookie if this query parameter is supplied.

Note, however, that the W3C recommends against using this for external requests.

=head2 C<BasicSessionCookie*>

These arguments set the parameters your session cookie will be created
with.  These are named similarly to the above parameters, namely the prefix
should reflect your local realm name (or "BasicSession" if you aren't doing
authentication). A common thing one might want to set is the expirytime of the session cookie. This can be set using the formats described in L<CGI::Cookie>, e.g.:

  PerlSetVar BasicSessionCookieExpires +2d

will make the cookie expire two days from now.

For more information, please see L<Apache::AuthCookie>.

=head2 C<AxKit::XSP::BasicSession Support>

This plugin was created to complement AxKit::XSP::BasicSession, but can be used
without the taglib.

Every session access, the session key "_last_accessed_time" is set to the current
date-timestamp.  When a new session is created, the session key "_creation_time" is
set to the current date-timestamp.

=head1 ERRORS

To tell you the truth, I haven't tested this enough to know what happens when it fails.
I'll update this if any glaring problems are found.

=head1 AUTHOR

Michael A Nachbaur, mike@nachbaur.com
Kjetil Kjernsmo, kjetilk@cpan.org


=head1 COPYRIGHT

Copyright (c) 2001-2004 Michael A Nachbaur, 2004 Kjetil Kjernsmo. All
rights reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<AxKit>, L<AxKit::XSP::BasicSession>, L<Apache::Session>, L<Apache::Session::Flex>

=cut

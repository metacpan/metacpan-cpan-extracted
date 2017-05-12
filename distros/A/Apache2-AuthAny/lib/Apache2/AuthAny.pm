package Apache2::AuthAny;

use strict;
use Data::Dumper qw(Dumper);
use Apache2::Module ();
use Apache2::ServerUtil ();
use Apache2::Const -compile => qw(OR_AUTHCFG TAKE1 TAKE2 OR_ALL FLAG ITERATE :log);


=head1 NAME

Apache2::AuthAny - Authentication with any provider or mechanism

=head1 VERSION

Version 0.201

=cut

our $VERSION = '0.201';

=head1 SYNOPSIS

Apache configuration ...

 PerlSetEnv AUTH_ANY_ROOT       /usr/share/authany
 PerlSetEnv AUTH_ANY_CONFIG_ROOT  /etc/authany
 PerlSetEnv AUTH_ANY_DB         mysql
 PerlSetEnv AUTH_ANY_DB_PW_FILE /etc/authany/db-passwd
 PerlSetEnv AUTH_ANY_DB_USER    authany
 PerlSetEnv AUTH_ANY_DB_NAME    auth_any
 #PerlSetEnv AUTH_ANY_DB_HOST    remote_host_if_needed
 
 PerlRequire              /usr/share/authany/startup.pl
 PerlLoadModule Apache2::AuthAny

 <VirtualHost *:443>
	DocumentRoot /var/www/htdocs
        ...

        # for Apache2::AuthAny
	<Location /aa_auth/basic*/*>
              AuthType Basic
              AuthName AABasic
              AuthUserFile /etc/authany/config/htpasswd
              Require valid-user
	</Location>

	<Location /aa_auth/uw>
            AuthType shibboleth
            ShibRequireSessionWith UW
            ShibRequestSetting forceAuthn 1
            Require valid-user
	</Location>
        # ...
 </VirtualHost>

Contents of /var/www/htdocs/private/.htaccess

 AuthType auth-any
 AuthAnyGateURL /our-gate/gate.php
 Require role our_project_administrators
 Require user john_the_ceo

Contents of /var/www/htdocs/our-gate/gate.php

 ...
 <h2>Select the method you would like to use to log in:</h2>
 <div class="gate-providers">
   <div class="gate-provider">
     <button onclick="document.location = '<?= $uwt_auth_url ?>'; return false">
       <img src="images/uw.gif" alt="UW Shibboleth Login">
     </button>
   </div>
   ...

=head1 DESCRIPTION

Apache2::AuthAny is extensible authentication layer providing support for any authentication mechanism or provider.

AuthAny registers handlers for the Apache headerParser,
authentication, fixup, and response phases. The Authentication phase
handler checks for existance of an "AA_PID" cookie. If this cookie is
not found or not associated with a logged in user, the handler returns
a redirect to a gateway ("GATE") page. The gate page offers a link for
each identity provider. Each of these URLs (beginning with
"/aa_auth/") is protected by a different authentication module
configured with standard Apache "<Directory>" directives and
appropriate "Require" directives. If authentication succeeds, the
"AA_PID" cookie is set in the browser and in the AuthAny
database. Apache redirects to the originally requested URL. Since the
cookie now exists, access is permitted.

=head2 Environment Variables

AuthAny passes environment variables to applications running in
the response phase.

=head3 REMOTE_USER

If the user has successfully authenticated with one of the
providers, the "REMOTE_USER" variable gets set. If the
userId/provider has an entry in the userIdent table, "REMOTE_USER"
will be set to the username value in the user table. Otherwise, it
will be set to <userId>|<provider>

"REMOTE_USER" is a standard variable set by all Apache
authentication modules. Without the identity resolution provided
by AuthAny, the protected application would need to perform this
function. (assuming we wish to consider someone logging in with
multiple providers as the same person)

=head3 AA_USER

Set to the identity supplied by the provider.

=head3 AA_PROVIDER

Set to the provider or authentication mechanisim name.

=head3 AA_SESSION

Set to 1 if the user has logged in the current browser
session.

=head3 AA_TIMEOUT

This variable is set if the user's session has not yet timed
out. The value is the number of seconds that can elapse before the
user gets timed out.

=head3 AA_STATE

This value can be one of "logged_out", "recognized", or
"authenticated". A user who has never logged in, has removed their
"AA_PID" cookie, or has logged out will be in the "logged_out"
state. After signing in, AA_STATE will be "authenticated", however
if 'AA_TIMEOUT' seconds have elapsed since the last time a URL was
accessed, the user is timed out, and AA_STATE will change to
"recognized".


=head3 AA_IDENTITIES

An identified user might have more than authId|provider
combination that they can log in with. This variable is set to a
list of all the user's identities

=head3 AA_ROLES

This variable will be set only if the user is identified, and
there are roles associated with that user in the userRole table.

Environment variables beginning with "AA_IDENT_" take their values
from the "user" table, and are only set if the user is identified.

=head3 AA_IDENT_UID

Set to the primary key in the user table.

=head3 AA_IDENT_username

Same as REMOTE_USER for identified users.

=head3 AA_IDENT_active

Users whose "active" value is not "1" are denied access to
directories protected with any "Require" directive (eg. "Require
valid-user")

In addition to the above, the value of any field in the "user" table
will be passed as AA_IDENT_. The demo database includes "firstName",
"lastName", and "created".

=head2 Logout

AuthAny provides a logout feature that allows the user to log out
without closing her browser. The feature has two functions. It sets
the state in the database to "logged_out". It also logs the user out
of Basic auth and Shibboleth. Without the second function, a user
would simply be able to click again on the GATE's provider link and
get right back into the protected application. Google authentication
is not included in this second logout function, however Google's login
state is set to expire after about a minute, after which the user must
log in again.

=cut

my %level = (error  => Apache2::Const::LOG_ERR,
             warn   => Apache2::Const::LOG_WARNING,
             notice => Apache2::Const::LOG_NOTICE,
             info   => Apache2::Const::LOG_INFO,
             debug  => Apache2::Const::LOG_DEBUG,
    );

__PACKAGE__->init;

sub init {
    my $self = shift;

     my @directives = (
         {
             name         => 'AuthAnyGateURL',
             args_how     => Apache2::Const::TAKE1,
             errmsg       => 'Custom GATE page',
         },

         {
             name         => 'AuthAnySkipAuthentication',
             args_how     => Apache2::Const::ITERATE,
             errmsg       => 'Usage: AuthAnySkipAuthentication uri-pattern1 [uri-pattern2 ...]',
         },

         {
             name         => 'AuthAnyBasicAuthUserFile',
             req_override => Apache2::Const::OR_ALL,
             args_how     => Apache2::Const::TAKE1,
             errmsg       => 'Basic auth .htpasswd file',
         },

         {
             name         => 'AuthAnyTimeout',
             args_how     => Apache2::Const::TAKE1,
             errmsg       => 'seconds',
         },


         );

    eval {
        Apache2::Module::add($self, \@directives);
        my $s = Apache2::ServerUtil->server;
        $s->push_handlers( PerlMapToStorageHandler    =>
                           'Apache2::AuthAny::MapToStorageHandler' );
        $s->push_handlers( PerlHeaderParserHandler    =>
                           'Apache2::AuthAny::RequestConfig' );
    };
    warn $@ if $@;

}

=head1 DIRECTIVES

=head2 AuthAnyGateURL (required)

If a user needs to log in, she is redirected to a GATE page which
contains a list of provider links. This directive defines
the URL to the gate page.

=cut

sub AuthAnyGateURL {
    my ($self, $params, $arg) = @_;
    $self->{AuthAnyGateURL} = $arg;
}

=head2 AuthAnySkipAuthentication

This directive accepts a list of URL patterns for which
the autentication and authorization phases will be skipped.

=cut

sub AuthAnySkipAuthentication {
    my ($self, $params, $arg) = @_;
    push @{$self->{AuthAnySkipAuthentication}}, $arg;
}

=head2 AuthAnyBasicAuthUserFile

The basic authentication user file for interactive login is defined
in the Apache configuration. This directive allows a basic auth
user file to be checked with each request to a protected resource.
In this way, the request can include an HTTP "Authorization" header
to allow scripting. No AA_AUTH cookie is required.

=cut

sub AuthAnyBasicAuthUserFile {
    my ($self, $params, $arg) = @_;
    $self->{AuthAnyBasicAuthUserFile} = $arg;
}

=head2 AuthAnyTimeout

This directive allows a default timeout to be set, after which
an "authenticated" user will become only "recognized". The value
set by AuthAnyTimeout can be overridden for any identified user
by specifying a "timeout" value in the "auth_user" db table.

=cut

sub AuthAnyTimeout {
    my ($self, $params, $arg) = @_;
    $self->{AuthAnyTimeout} = $arg;
}

=head2 AuthType auth-any (required)

This directive turns AuthAny on and causes AuthAny's environment
variables to be passed to code running in the response phase.

=head2 Require <options>

=head3 Require valid-user

The user must sign in with any mechanism/provider however
the user need not be in the userIdent db table.

=head3 Require identified-user

The user must have an entry in the userIdent and user table, and
not be in a deactivated state.

=head3 Require user <user1 [user2 ...]>

The specified users are allowed. Note, users who do not have an entry
in the userIdent table are seen by the system as "id|provider". For
example if you want to grant access to the user "john" when logging in
using "basic" authentication, and john does not have an entry in the
userIdent table, you would use the following directive:

 Require user john|basic

=head3 Require role <role1 [role2 ...]>

Users holding the specified roles are allowed access

=head3 Require authenticated

Users are not permitted if they they have timed out and thus are no
longer authenticated.

=head3 Require session

Users are not permitted if they they haven't logged in the current
browser session. This allows the administrator to force logout when
the user exits her browser.

=head1 ISSUES

=head2 mod_dir ignores AuthType

If a request is made to a directory, mod_dir will try to use one
of the index file names specified by "DirectoryIndex". It appears
that mod_dir is ignoring the "AuthName auth-any" directive and is
trying to use basic authentication resulting in errors such as,

 "configuration error:  couldn't check user.  No user file?: /gossamer/index.php"

A workaround is to use mod_rewrite on directories:

 RewriteEngine On
 RewriteRule ^gossamer/$ /gossamer/index.php
 RewriteRule ^$ /gossamer/index.php

=head1 TODO

=head2 Google authentication

Google authentication is directly included in Apache2::AuthAny,
rather than being set up through Apache configuration. This
was done because at the time when AuthAny was written, Attribute
Exchange was not available through mod_auth_openID. Once an
acceptable OpenID library is found and tested that will run
in the authentication phase, the Google authentication
should be removed from the codebase.

=head2 GATE API

A variety of error messages are made available to the GATE page.
(timeout, unknown user, no role, etc). A PHP file is provided
that makes it easy to implement a GATE page. The administrator
might prefer not to use PHP for the GATE page, so the GATE error
API should be clarified, and documented.

=head2 Server errors

There are some system errors, such as an unavailable database
that will send the user to the GATE page with a "Technical
Difficulties" error message. Errors such as this should
probably produce a server error (500) and be handled by
a seperately defined custom ErrorDocument.

=head1 AUTHOR

Kim Goldov, C<< <kim at goldov.com> >>

=head1 ACKNOWLEDGEMENTS

AuthAny was developed at the Clinical Informatics Research Group of
the University of Washington. Supporting staff included,

 Eric Webster
 Justin McReynolds
 Bill Lober
 Debra Revere
 Paul Bugni
 Svend Sorensen
 Blaine Reeder

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2011, University of Washington

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache2::AuthAny

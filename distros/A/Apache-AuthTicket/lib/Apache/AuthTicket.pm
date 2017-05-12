package Apache::AuthTicket;
BEGIN {
  $Apache::AuthTicket::VERSION = '0.93';
}

# ABSTRACT: Cookie Based Access and Authorization Module

use strict;
use base qw(Apache::AuthTicket::Base Apache::AuthCookie);
use Apache::Constants;
use Apache::Log;
use MRO::Compat;

sub push_handler {
    my ($class, $phase, $handler) = @_;

    return Apache->push_handlers($phase, $handler);
}

sub logout ($$) {
    my ($class, $r) = @_;

    if (lc $r->dir_config('Filter') eq 'on') {
        $r->filter_register;
    }

    return $class->next::method($r);
}

sub set_user {
    my ($self, $user) = @_;

    $self->request->connection->user($user);
}

sub apache_const {
    my ($self, $const) = @_;
    no strict 'refs';

    return *{"Apache::Constants::$const"}->();
}

1;



=pod

=head1 NAME

Apache::AuthTicket - Cookie Based Access and Authorization Module

=head1 VERSION

version 0.93

=head1 SYNOPSIS

 # in httpd.conf
 PerlModule Apache::AuthTicket
 PerlSetVar FooTicketDB DBI:mysql:database=mschout;host=testbed
 PerlSetVar FooTicketDBUser test
 PerlSetVar FooTicketDBPassword secret
 PerlSetVar FooTicketTable tickets:ticket_hash:ts
 PerlSetVar FooTicketUserTable myusers:usename:passwd
 PerlSetVar FooTicketPasswordStyle cleartext
 PerlSetVar FooTicketSecretTable ticket_secrets:sec_data:sec_version
 PerlSetVar FooTicketExpires 15
 PerlSetVar FooTicketLogoutURI /foo/index.html
 PerlSetVar FooTicketLoginHandler /foologin
 PerlSetVar FooTicketIdleTimeout 1
 PerlSetVar FooPath /
 PerlSetVar FooDomain .foo.com
 PerlSetVar FooSecure 1
 PerlSetVar FooLoginScript /foologinform

 <Location /foo>
     AuthType Apache::AuthTicket
     AuthName Foo
     PerlAuthenHandler Apache::AuthTicket->authenticate
     PerlAuthzHandler Apache::AuthTicket->authorize
     require valid-user
 </Location>

 <Location /foologinform>
     AuthType Apache::AuthTicket
     AuthName Foo
     SetHandler perl-script
     Perlhandler Apache::AuthTicket->login_screen
 </Location>

 <Location /foologin>
     AuthType Apache::AuthTicket
     AuthName Foo
     SetHandler perl-script
     PerlHandler Apache::AuthTicket->login
 </Location>
 
 <Location /foo/logout>
     AuthType Apache::AuthTicket
     AuthName Foo
     SetHandler perl-script
     PerlHandler Apache::AuthTicket->logout
 </Location>

=head1 DESCRIPTION

This module provides ticket based access control.  The theory behind this is
similar to the system described in the eagle book.

This module works using HTTP cookies to check if a user is authorized to view a
page.  I<Apache::AuthCookie> is used as the underlying mechanism for managing
cookies.

This module was designed to be as extensible as possible.  Its quite likely
that you will want to create your own subclass of I<Apache::AuthTicket> in
order to customize various aspects of this module (show your own versions of
the forms, override database methods etc). 

This system uses cookies to authenticate users.  When a user is authenticated
through this system, they are issued a cookie consisting of the time, the
username of the user, the expriation time of the cookie, a "secret" version
(described later), and a cryptographic signature.  The cryptographic signature
is generated using the MD5 algorithm on the cookie data and a "secret" key that
is read from a database.  Each secret key also has a version number associated
with it.  This allows the site administrator to issue a new secret periodically
without invalidating the current valid tickets.   For example, the site
administrator might periodically insert a new secret key into the databse
periodically, and flush secrets that are more than 2 days old.  Since the
ticket issued to the user contains the secret version, the authentication
process will still allow tickets to be authorized as long as the corresponding
secrets exist in the ticket secrets table. 

The actual contents and length of secret data is left to the site
administrator. A good choice might be to read data from /dev/random, unpack it
into a hex string and save that.

This system should be reasonably secure becuase the IP address of the end user
is incorporated into the cryptographic signature. If the ticket were
intercepted, then an attacker would have to steal the user's IP address in
order to be able to use the ticket.  Plus, since the tickets can expire
automatically, we can be sure that the ticket is not valid for a long period of
time.  Finally, by using the I<Secure> mode of I<Apache::AuthCookie>, the
ticket is not passed over unencrypted connections.  In order to attack this
system, an attacker would have to exploit both the MD5 algorightm as well as
SSL. Chances are, by the time the user could break both of these, the ticket
would no longer be valid.

=head1 CONFIGURATION

There are two things you must do in order to configure this module: 

 1) configure your mod_perl apache server
 2) create the necessary database tables.

=head2 Apache Configuration - httpd.conf

There are two ways that this module could be configured.  Either by using a
function call in startup.pl, or by configuring each handler explicitly in
httpd.conf.  If you decide to mix and match using calls to Apache::AuthTicket->configure() with directives in httpd.conf, then remember that the following precedence applies:

 o If a directive is specified in httpd.conf, it will be used.
 o else if a directive is specified by configure(), then the 
   configure() value will be used.
 o else a default value will be used.

Default values are subject to change in later versions, so you are better of
explicitly configuring all values and not relying on any defaults.

There are four blocks that need to be entered into httpd.conf.  The first of
these is the block specifying your access restrictions.  This block should look
somrthing like this:

 <Location /foo>
     AuthType Apache::AuthTicket
     AuthName Foo
     PerlAuthenHandler Apache::AuthTicket->authenticate
     PerlAuthzHandler Apache::AuthTicket->authorize
     require valid-user
 </Location>

The remaining blocks control how to display the login form, and the login and
logout urls.  These blocks should look similar to this:

 <Location /foologinform>
     AuthType Apache::AuthTicket
     AuthName Foo
     SetHandler perl-script
     Perlhandler Apache::AuthTicket->login_screen
 </Location>
 
 <Location /foologin>
     AuthType    Apache::AuthTicket
     AuthName    Foo
     SetHandler  perl-script
     PerlHandler Apache::AuthTicket->login
 </Location>
 
 <Location /foo/logout>
     AuthType Apache::AuthTicket
     AuthName Foo
     SetHandler perl-script
     PerlHandler Apache::AuthTicket->logout
 </Location>

=head2 Apache Configuration - startup.pl

Any I<Apache::AuthTicket> configuration items can be set in startup.pl.  You
can configure an AuthName like this:

 Apache::AuthTicket->configure(String auth_name, *Hash config)

Note that when configuring this way you dont prefix the configuration items
with the AuthName value like you do when using PerlSetVar directives.

Note: You must still include I<Apache::AuthCookie> configuration directives in 
httpd.conf when configuring the server this way.  These items include:

    PerlSetVar FooPath /
    PerlSetVar FooDomain .foo.com
    PerlSetVar FooSecure 1
    PerlSetVar FooLoginScript /foologinform

example:
 Apache::AuthTicket->configure('Foo', {
     TicketDB            => 'DBI:mysql:database=test;host=foo',
     TicketDBUser        => 'mschout',
     TicketDBPassword    => 'secret',
     TicketTable         => 'tickets:ticket_hash:ts',
     TicketUserTable     => 'myusers:usename:passwd',
     TicketPasswordStyle => 'cleartext',
     TicketSecretTable   => 'ticket_secrets:sec_data:sec_version',
     TicketExpires       => '15',
     TicketLogoutURI     => '/foo/index.html',
     TicketLoginHandler  => '/foologin',
     TicketIdleTimeout   => 5
 });

Valid configuration items are:

=over 3

=item B<TicketDB>

This directive specifys the DBI URL string to use when connecting to the
database.  Also, you might consider overloading the B<dbi_connect> method to
handle setting up your db connection if you are creating a subclass of this
module.

example: dbi:Pg:dbname=test

=item B<TicketDBUser>

This directive specifys the username to use when connecting to the databse.

=item B<TicketDBPassword>

This directive specifys the password to use when connecting to the databse.

=item B<TicketTable>

This directive specifys the ticket hash table as well as the column name for
the hash.

Format: table_name:ticket_column_name:timestamp_column

Example: tickets:ticket_hash:ts

=item B<TicketUserTable>

This directive specifys the users table and the username and password column
names.

Format: table_name:username_column:password_column

Example: users:usrname:passwd

=item B<TicketPasswordStyle>

This directive specifys what type of passwords are stored in the database.  The
default is to use I<cleartext> passwords.  Currently supported password styles
are:

=over 3

=item I<cleartext>

This password style is just plain text passwords.  When using this password
style, the supplied user password is simply compared with the password stored
in the database.

=item I<md5>

This password style generates an MD5 hex hash of the supplied password before
comparing it against the password stored in the database.  Passwords should be
stored in the database by passing them through Digest::MD5::md5_hex().

=item I<crypt>

This password style uses traditional crypt() to encrypt the supplied password
before comparing it to the password saved in the database.

=back

=item B<TicketSecretTable>

This directive specifys the server secret table as well as the names of the 
secret data column and the version column.

Format: table_name:data_column:version_column

Example: ticketsecrets:sec_data:sec_version

=item B<TicketExpires>

This directive specifys the number of minutes that tickets should remain
valid for.  If a user exceeds this limit, they will be forced to log in
again.

This should not be confused with the inherited AuthCookie setting C<Expire>,
which is the I<cookie> expiration time.  C<TicketExpires> controls the
expiration of the ticket, not the cookie.

=item B<TicketIdleTimeout>

This directive specifys the number of minutes of inactivity before a ticket
is considered invalid.  Setting this value to 5 for example would force a
re-login if no requests are recieved from the user in a 5 minute period.

The default for this value is 0, which disables this feature.  If this number
is larger than I<TicketExpires>, then this setting will have no effect.

=item B<TicketLogoutURI>

This directive specifys the URL that the user should be sent to after 
they are successfully logged out (this is done via a redirect).

Example: /logged_out_message.html

=item B<TicketCheckIP> (default: on)

This controlls whether or not the client IP address is included in the ticket
hash.  The default is 'on'.  If you turn this off, then the client ip address
will not be checked.  It is sometimes not desirable to check the client ip if
the clients are behind load balancers and subsequent requests might come in
from a different IP.

=item B<TicketCheckBrowser> (default: off)

This controlls whether or not the C<USER_AGENT> string is included in the
ticket hash.  This can be used in conjunction with, or instead of
C<TicketCheckIP> to prevent tampering with the ticket.

=back

=head2 Database Configuration

Three database tables are needed for this module:

=over 3

=item B<users table>

This table stores the actual usernames and passwords of the users.  This table
needs to contain at least a username and password column.  This table is
confgured by the I<TicketUserTable> directive.

 example:

 CREATE TABLE users (
     usename VARCHAR(32) NOT NULL,
     passwd  VARCHAR(32) NOT NULL
 );

=item B<tickets table>

This table stores the ticket hash for each ticket.  This information must be
stored locally so that users can be forcefully logged out without worrying if
the HTTP cookie doesn't get deleted.

 example:

 CREATE TABLE tickets (
    ticket_hash CHAR(32) NOT NULL,
    ts          INT NOT NULL,
    PRIMARY KEY (ticket_hash)
 );

=item B<secrets table>

This table contains the server secret and a numeric version for the secret.
This table is configured by the I<TicketSecretTable> directive.

 example:

 CREATE TABLE ticketsecrets (
     sec_version  SERIAL,
     sec_data     TEXT NOT NULL
 );

=back

=head1 METHODS

This is not a complete listing of methods contained in I<Apache::AuthTicket>.
Rather, it is a listing of methods that you might want to overload if you were
subclassing this module.  Other methods that exist in the module are probably
not useful to you.

Feel free to examine the source code for other methods that you might choose to
overload.

=over 3

=item void make_login_screen($r, String action, String destination)

This method creats the "login" screen that is shown to the user.  You can
overload this method to create your own login screen.  The log in screen only
needs to contain a hidden field called "destination" with the contents of
I<destination> in it, a text field named I<credential_0> and a password field
named I<credential_1>.  You are responsible for sending the http header as well
as the content.  See I<Apache::AuthCookie> for the description of what each of
these fields are for.

I<action> contains the action URL for the form.  You must set the action of
your form to this value for it to function correctly.

I<Apache::AuthTicket> also provides a mechanism to determine why the login for
is being displayed.  This can be used in conjunction with
I<Apache::AuthCookie>'s "AuthCookieReason" setting to determine why the user is
being asked to log in.  I<Apache::AuthCookie> sets
$r->prev->subprocess_env("AuthCookieReason") to either "no_cookie" or
"bad_cookie" when this page is loaded.  If the value is "no_cookie" then the
user is being asked to log in for the first time, or they are logging in after
they previously logged out.  If this value is "bad_cookie" then
I<Apache::AuthTicket> is asking them to re-login for some reason.  To determine
what this reason is, you must examine
$r->prev->subprocess_env("AuthTicketReason").  I<AuthTicketReason> can take the
following values:

=over 3

=item malformed_ticket

This value means that the ticket is malformed.  In other words, the ticket does
not contain all of the required information that should be present.

=item invalid_hash

This value means that the hash contained in the ticket does not match any
values in the tickets database table.  This might happen if you are
periodically clearing out old tickets from the database and the user presents a
ticket that has been deleted.

=item expired_ticket

This value means that the ticket has expired and the user must re-login to be
issued a new ticket.

=item missing_secret

This value means that the server secret could not be loaded.

=item idle_timeout

This value means that the user has exceeded the I<TicketIdleTimeout> minutes of
inactivity, and the user must re-login.

=item tampered_hash

This value indicates that the ticket data does not match its cryptographic
signature, and the ticket has most likely been tampered with.  The user is
forced to re-login at this point.

=back

You can use these values in your I<make_login_screen()> method to display a
message stating why the user must login (e.g.: "you have exceeded 5 minutes of
inactivity and you must re-login").

=item DBI::db dbi_connect()

This method connects to the TicketDB data source. You might overload this
method if you have a common DBI connection function. For example:

 sub dbi_connect {
     my ($self) = @_;
     return Foo::dbi_connect();
 }

Note that you can also adjust the DBI connection settings by setting TicketDB,
TicketDBUser, and TicketDBPassword in httpd.conf.

=back

=head1 CREDITS

The idea for this module came from the Ticket Access system in the eagle book,
along with several ideas discussed on the mod_perl mailing list.

Thanks to Ken Williams for his wonderful I<Apache::AuthCookie> module, and for
putting in the necessary changes to I<Apache::AuthCookie> to make this module
work!

=head1 SEE ALSO

L<perl>, L<mod_perl>, L<Apache>, L<Apache::AuthCookie>

=head1 SOURCE

The development version is on github at L<http://github.com/mschout/apache-authticket>
and may be cloned from L<git://github.com/mschout/apache-authticket.git>

=head1 BUGS

Please report any bugs or feature requests to bug-apache-authticket@rt.cpan.org or through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Apache-AuthTicket

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Michael Schout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


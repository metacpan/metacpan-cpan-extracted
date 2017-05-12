package CGI::Authen::Simple;

use strict;
use CGI;
use CGI::Cookie;
use Template;

=head1 NAME

CGI::Authen::Simple - Simple cookie-driven unsessioned form-based authentication

=head1 SYNOPSIS

 use CGI::Authen::Simple;

 my $auth = CGI::Authen::Simple->new();
 $auth->logged_in() || $auth->auth();

 # do stuff here

 # if you need it, you can access the user's credentials like so:
 my $username = $auth->{'profile'}->{'username'};

 # assume your account table had other attributes, like full_name char(64)
 my $fullname = $auth->{'profile'}->{'full_name'};

 # their password is never returned in plain text
 print $auth->{'profile'}->{'password'};
 # prints the MySQL hash of their password

=head1 DESCRIPTION

This module provides extremely simple forms-based authentication for web
applications. It has reasonable defaults set, and if your database conforms
to those defaults, you can instantiate a new object with no parameters, and
it will handle all the authentication and cookie settings for you.

=head1 METHODS

=cut

our $VERSION = '1.0';

=over

=item B<new()>

Returns a new CGI::Authen::Simple object. Accepts a single hashref as a parameter. The hashref contains config information:

=over

=item *
dbh - a DBI database handle to the database containing the account information. REQUIRED.

=item *
EXIT_ON_DISPLAY - if auth() is required to draw a page, should it exit()? Defaults to true.
If you are running mod_perl, I recommend you set this to 0, and wrap your auth-protected code
in a logged_in() check. See the documentation for auth().

=item *
USERID - the database column containing a unique account ID. The ID can be anything, however I
recommend a unique integer ID.

=item *
USERNAME - the column corresponding to their username. Usernames do not have to be unique, however
username/password pairs must be unique or you will get potentially unexpected results.

=item *
PASSWORD - the column in the database corresponding to the user's password.

=item *
HASH_FUNC - one of ('none','old_password','password','md5','sha','sha1').
These correspond to their named hashing functions in mysql. If your passwords are stored as
plaintext in the database, use none. Encrypted passwords are not currently supported.
Default: none

=item *
TABLE - the name of the table that contains the above three columns.

=item *
HTML_TITLE - the title for the page. Defaults to lc($ENV{'HTTP_HOST'}) . ' : please log in';

=item *
HTML_HEADER - HTML that will be printed inside a header block for the page. Same default as HTML_TITLE

=item *
HTML_FOOTER - HTML that will be printed inside a footer block for the page. Defaults to
Login handled by <a href="http://search.cpan.org/~opiate/">CGI::Authen::Simple</a> version $VERSION

=item *
ext_auth - code reference. The function called by this reference can do anything it has access to do,
and is expected to return a username and password to be authenticated. This is useful for example, if
you wanted to log people in via SSL certificates or UserAgent settings. For example, you could check
their UserAgent in the function, and derive a username and password from it -- or you could find out what
client certificate someone has connected using on an SSL-enabled webserver, and derive a username and
password from that.

=back

=cut

sub new
{
    my ($pkg, $args) = @_;

    # a DBH is necessary
    die "You must pass in a database handle" if !defined $args->{'dbh'};

    # do we exit if auth is required to display an HTML page?
    $args->{'EXIT_ON_DISPLAY'} = 1 if !defined $args->{'EXIT_ON_DISPLAY'};

    # database settings
    $args->{'USERID'} = 'id' if !defined $args->{'USERID'};
    $args->{'USERNAME'} = 'username' if !defined $args->{'USERNAME'};
    $args->{'PASSWORD'} = 'password' if !defined $args->{'PASSWORD'};
    $args->{'HASH_FUNC'} = 'none' if !defined $args->{'HASH_FUNC'};
    if($args->{'HASH_FUNC'} !~ /^(?:none|(?:old_)password|md5|sha1?)$/i)
    {
        warn "Invalid hash function passed in, defaulting to 'none'";
        $args->{'HASH_FUNC'} = 'none';
    }
    $args->{'TABLE'} = 'accounts' if !defined $args->{'TABLE'};

    # HTML things
    $args->{'HTML_TITLE'} = lc($ENV{'HTTP_HOST'}) . ' : please log in' if !defined $args->{'HTML_TITLE'};
    $args->{'HTML_HEADER'} = '<p align="center">' . lc($ENV{'HTTP_HOST'}) . ' : please log in</p>' if !defined $args->{'HTML_HEADER'};
    $args->{'HTML_FOOTER'} = '<p align="center">Login handled by <a href="http://search.cpan.org/~opiate/">CGI::Authen::Simple</a> '
                           . 'version ' . $VERSION . '</p>' if !defined $args->{'HTML_FOOTER'};

    my $self = bless { %$args, logged_in => 0, profile => {} }, $pkg;

    return $self;
}

=item B<logged_in()>

Uses cookies to determine if a user is logged in. Returns true if user is logged in. If a row is retrieved from the DB,
then all the columns making up the row for that user in the accounts table will be pulled and stored as the user's profile,
which is accessible as a hashref via $auth->{'profile'}.

=cut

sub logged_in
{
    my $self = shift;
    my $to_return = 1;

    if(!$self->{'logged_in'})
    {
        my (%cookie) = fetch CGI::Cookie;

        foreach ( qw(userid username password) )
        {
            if(!exists($cookie{$_}) || $cookie{$_}->value eq '')
            {
                $to_return = 0;
                last;
            }
        }

        if($to_return == 1)
        {
            my $ph = ($self->{'HASH_FUNC'} =~ /none/i)
                   ? ", " . uc($self->{'HASH_FUNC'}) . "($self->{'PASSWORD'}) AS $self->{'PASSWORD'}"
                   : '';

            my $wph = ($self->{'HASH_FUNC'} !~ /none/i)
                    ? "$self->{'PASSWORD'} = ?"
                    : uc($self->{'HASH_FUNC'}) . "($self->{'PASSWORD'}) = ?";

            my $profile = $self->{'dbh'}->selectrow_hashref('SELECT *' . $ph . ' FROM ' . $self->{'TABLE'} . ' WHERE ' . $self->{'USERID'} . ' = ? AND ' . $self->{'USERNAME'} . ' = ? AND ' . $wph, undef, $cookie{'userid'}->value, $cookie{'username'}->value, $cookie{'password'}->value);

            if(!$profile)
            {
                $to_return = 0;
            }
            else
            {
                $self->{'profile'} = $profile;
            }
        }

        $self->{'logged_in'} = $to_return;
    }

    return $to_return;
}

=item B<auth()>

Authenticates a user if data was posted containing a username and password pair. If authentication was unsuccessful or
they did not pass a username/password pair, they are displayed a login screen. If we retrieve a row (valid username
and password), then grab the rest of the columns from that table, and store them internally as the user's profile.

Note: If a login screen is displayed, the value of EXIT_ON_DISPLAY is checked. B<If EXIT_ON_DISPLAY is true (1),
then the function will exit. This is the default behaviour.> As far as I am aware, this is highly undesirable in
mod_perl applications, so please be sure you've taken that into consideration. If EXIT_ON_DISPLAY is set to false,
the function will not exit, and control will be returned to the calling script. In this case, please wrap your code
in a surrounding:

 if($auth->logged_in())
 {
     # do stuff here
 }

code block, or else you will be displaying not only the auth screen, but anything that would be displayed by your code.

=cut

sub auth
{
    my $self = shift;
    my $cgi = new CGI;

    my $vars = {
        HTML_HEADER => $self->{'HTML_HEADER'},
        HTML_FOOTER => $self->{'HTML_FOOTER'},
        HTML_TITLE  => $self->{'HTML_TITLE'},
    };

    my $username = $cgi->param('username');
    my $password = $cgi->param('password');

    # if we don't have a username and password from CGI, check for an external auth mechanism to provide a username and password
    if(!$username || !$password)
    {
        if(defined $self->{'ext_auth'})
        {
            ($username, $password) = $self->{'ext_auth'}->();
        }
    }

    if($username && $password)
    {
        my $ph = ($self->{'HASH_FUNC'} =~ /none/i)
               ? ", " . uc($self->{'HASH_FUNC'}) . "($self->{'PASSWORD'}) AS $self->{'PASSWORD'}"
               : '';

        my $wph = ($self->{'HASH_FUNC'} !~ /none/i)
                ? "$self->{'PASSWORD'} = " . uc($self->{'HASH_FUNC'}) . "(?)"
                : "$self->{'PASSWORD'} = ?";

        my $profile = $self->{'dbh'}->selectrow_hashref('SELECT *' . $ph
                . ' FROM ' . $self->{'TABLE'} . ' WHERE ' 
                . $self->{'USERNAME'} . ' = ? AND ' . $wph,
                undef, $username, $password);

        if($profile)
        {
            my $username_cookie = new CGI::Cookie( -name=> 'username', -value => $profile->{'username'} );
            my $password_cookie = new CGI::Cookie( -name=> 'password', -value => $profile->{'password'} );
            my $userid_cookie   = new CGI::Cookie( -name=> 'userid',   -value => $profile->{'id'}       );

            print qq!Set-Cookie: $username_cookie\nSet-Cookie: $password_cookie\nSet-Cookie: $userid_cookie\n!;
            $self->{'logged_in'} = 1;
            $self->{'profile'} = $profile;
        }
        else
        {
            $vars->{'login_failed'} = 1;
        }
    }

    if(!$self->logged_in)
    {
        my $template = Template->new();
        print $cgi->header;
        $template->process(\*DATA, $vars) or die $template->error();

        if($self->{'EXIT_ON_DISPLAY'})
        {
            exit;
        }
    }
}

1;

=back

=head1 TODO

 - template / CSS overrides
 - needs to work with any DB software (since it just takes a DBH, maybe use SQL::Abstract to generate a
   cross DB compatible query.

=head1 SEE ALSO

CGI::Cookie, CGI, Template

=head1 AUTHOR

Shane Allen E<lt>opiate@gmail.comE<gt>

=head1 ACKNOWLEDGEMENTS

=over

=item *
This core functionality of this module was developed during my employ at
HRsmart, Inc. L<http://www.hrsmart.com> and its public release was
graciously approved.

=back

=head1 COPYRIGHT

Copyright 2005, Shane Allen. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>

<head>
<title>[% HTML_TITLE %]</title>
<style type="text/css">
#container {
    width: 560px;
    margin: 10px;
    margin-left: auto;
    margin-right: auto;
    padding: 10px;
}

#banner {
    font-family: Georgia, "Times New Roman", Times, serif;
    font-size: 0.8em;
    padding: 5px;
    margin-bottom: 25px;
    border: 1px solid gray;
    background-color: rgb(223, 229, 235);
}

#content {
    font-family: Georgia, "Times New Roman", Times, serif;
    font-size: 0.8em;
    padding: 5px;
}

#footer {
    clear: both;
    padding: 5px;
    margin-top: 5px;
    border: 1px solid gray;
    background-color: rgb(213, 219, 225);
}

.error {
    font-family: Georgia, "Times New Roman", Times, serif;
    font-size: 9pt;
    font-weight: bold;
    color: red;
}

#idtable {
        border: 1px solid #666;
}

#idtable tbody tr td {
        padding: 3px 8px;
        font-size: 8pt;
        border: 0px solid black;
        border-left: 1px solid #c9c9c9;
        text-align: center;
}

</style>
</head>

<body>
<div id="container">
    <div id="banner">[% HTML_HEADER %]</div>

    <form method="post">
    <div id="content" align="center">
        [%- IF login_failed %]
        <p align="center" class="error">Invalid username or password</p>
        [%- END %]
        <table id="idtable">
            <tr>
                <td>Username:</td>
                <td><input type="text" name="username" /></td>
            </tr>
            <tr>
                <td>Password:</td>
                <td><input type="password" name="password" /></td>
            </tr>
            <tr>
                <td align="center" colspan="2">
                    <input type="submit" name="submit" value="Submit" />
                </td>
        </table>
    </div>
    </form>

    <div id="footer">[% HTML_FOOTER %]</div>
</div>
</body>

</html>

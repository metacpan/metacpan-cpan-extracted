###########################################################
# CGI::Session::Auth
# Authenticated sessions for CGI scripts
###########################################################
#
# $Id: Auth.pm 32 2007-09-02 13:04:22Z geewiz $
#

package CGI::Session::Auth;
use base qw(Exporter);

use 5.008;
use strict;
use warnings;
use Carp;
use Digest::MD5 qw( md5_hex );

our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
);

our $VERSION = do { q$Revision: 32 $ =~ /Revision: (\d+)/; sprintf "1.%03d", $1; };

###########################################################
###
### general methods
###
###########################################################

###########################################################

sub new {
    
    ##
    ## class constructor
    ## see POD below
    ##
    
    my $class = shift;
    my ($params) = @_;
    
    $class = ref($class) if ref($class);
    # check required params
    my %classParams = (
        Session => ['CGI::Session'],
        CGI => ['CGI', 'CGI::Simple'],
    );
    foreach my $classParam (keys %classParams) {
        croak "Missing $classParam parameter" unless exists $params->{$classParam};
        croak "$classParam parameter is not a " . join(' or ', @{$classParams{$classParam}}) . " object"
           unless grep { $params->{$classParam}->isa($_) } @{$classParams{$classParam}};
    }
    
    my $self = {
    	
    	#
    	# general parameters
    	#
    	
        # parameter "Session": CGI::Session object
        session => $params->{Session},
        # parameter "CGI": CGI object
        cgi => $params->{CGI},
        # parameter "LoginVarPrefix": prefix of login form variables (default: 'log_')
        lvprefix => $params->{LoginVarPrefix} || 'log_',
        # parameter "IPAuth": enable IP address based authentication (default: 0)
        ipauth => $params->{IPAuth} || 0,
        # parameter "Log": enable logging (default: 0)
        log => $params->{Log} || 0,

		#
		# class members
		#
				        
        # the current URL
        url => $params->{CGI}->url,
        # logged-in status
        logged_in => 0,
        # user id
        userid => '',
        # user profile data
        profile => {},
        # Log::Log4perl logger, see "log" above
		logger => undef,
    };
    
    bless $self, $class;
    
    if ( $self->{log}) {
    	require Log::Log4perl;
		$self->{logger} = Log::Log4perl->get_logger($class);
		$self->_debug("logging enabled");
    }

    return $self;
}

###########################################################

sub authenticate {

	##
    ## authenticate current visitor
	##
	
    my $self = shift;
    
    # is this already a session by an authorized user?
    if ( $self->_session->param("~logged-in") ) {
        $self->_debug("User is already logged in in this session");
        # set flag
        $self->_loggedIn(1);
        # load user profile
        my $userid = $self->_session->param('~userid');
        $self->_loadProfile($userid);
        return 1;
    }
    else {
        $self->_debug("User is not logged in in this session");
        # reset flag
        $self->_loggedIn(0);
    }
    
    # maybe someone's trying to log in?
    my $lg_name = $self->_cgi->param( $self->{lvprefix} . "username" );
    my $lg_pass = $self->_cgi->param( $self->{lvprefix} . "password" );
    
    if ($lg_name && $lg_pass) {
        # Yes! Login data coming in.
        $self->_debug("User trying to log in");
        if ($self->_login( $lg_name, $lg_pass )) {
            $self->_debug("login successful, userid: ", $self->{userid});
            $self->_loggedIn(1);
            $self->_session->param("~userid", $self->{userid});
            $self->_session->clear(["~login-trials"]);
            return 1;
        }
        else {
            # the login seems to have failed :-(
            $self->_debug("Login failed");
            my $trials = $self->_session->param("~login-trials") || 0;
            return $self->_session->param("~login-trials", ++$trials);
        }
    }
    
    # or maybe we can authenticate the visitor by his IP address?
    if ($self->{ipauth}) {
        # we may check the IP
        if ($self->_ipAuth()) {
            $self->_debug("IP authentication successful, userid: ", $self->{userid});
            $self->_loggedIn(1);
            $self->_session->param("~userid", $self->{userid});
            $self->_session->clear(["~login-trials"]);
            return 1;
        }
    }
    
}

###########################################################

sub sessionCookie {
    
    ##
    ## make cookie with session id
    ##
    
    my $self = shift;
    
    my $cookie = $self->_cgi->cookie($self->_session->name() => $self->_session->id );
    return $cookie;
}

###########################################################

sub loggedIn {
    
    ##
    ## get internal logged-in flag
    ##
    
    my $self = shift;
    
    return $self->_loggedIn;
}

###########################################################

sub profile {
    
    ##
    ## accessor to user profile fields
    ##
    
    my $self = shift;
    my $key = shift;
    
    if (@_) {
        my $value = shift;
        $self->{profile}{$key} = $value;
        $self->_debug("set profile field '$key' to '$value'");
    }
    
    return $self->{profile}{$key};
}

###########################################################

sub hasUsername {
    
    ##
    ## check for given user name
    ##
    
    my $self = shift;
    my ($username) = @_;
    
    return ($self->{profile}{username} eq $username);
}

###########################################################

sub logout {
    
    ##
    ## revoke users logged-in status
    ##
    
    my $self = shift;
    
    $self->_loggedIn(0);
    $self->_info("User '", $self->{profile}{username}, "' logged out");
}

###########################################################

sub uniqueUserID {
    
    ##
    ## generate a unique 32-character user ID
    ##
    
    my ($username) = @_;
    
    return md5_hex(localtime, $username);
}

###########################################################
###
### backend specific methods
###
###########################################################

###########################################################

sub _login {
    
    ##
    ## check login credentials and load user profile
    ##
    
    my $self = shift;
    my ($username, $password) = @_;
    
    # allow only the guest user, for real applications use a subclass
    if ( ($username eq 'guest') && ( $password eq 'guest' ) ) {
        $self->_info("User '$username' logged in");
        $self->{userid} = "guest";
        $self->_loadProfile($self->{userid});
        return 1;
    }
    
    return 0;
}

###########################################################

sub _ipAuth {
    
    ##
    ## authenticate by the visitors IP address
    ##
    
    return 0;
}

###########################################################

sub _loadProfile {
    
    ##
    ## load the user profile for a given user id
    ##
    
    my $self = shift;
    my ($userid) = @_;
    
    # store some dummy values
    $self->{userid} = $userid;
    $self->{profile}{username} = 'guest';
}

###########################################################

sub saveProfile {

    ##
    ## save probably modified user profile
    ##

}

###########################################################

sub isGroupMember {
    
    ##
    ## check if user is in given group
    ##
    
    # abstract class w/o group functions, for real applications use a subclass
    return 0;
}

###########################################################
###
### internal methods
###
###########################################################

###########################################################

sub _debug {
	
	##
	## log debug message
	##
	
	my $self = shift;
	
	$self->{logger}->debug(@_) if $self->{logger};
}

###########################################################

sub _info {
	
	##
	## log info message
	##
	
	my $self = shift;
	
	$self->{logger}->info(@_) if $self->{logger};
}

###########################################################

sub _session {
    
    ##
    ## get reference on CGI::Session object
    ##
    
    my $self = shift;
    
    return $self->{session};
}

###########################################################

sub _cgi {
    
    ##
    ## get reference on CGI object
    ##
    
    my $self = shift;
    
    return $self->{cgi};
}

###########################################################

sub _encpw {

    ##
    ## encrypt password
    ##
    
    my ($self, $password) = @_;

    return md5_hex($password);
}

###########################################################

sub _loggedIn {
    
    ##
    ## accessor to internal logged-in flag and session parameter
    ##
    
    my $self = shift;
    
    if (@_) {
        # set internal flag
        if ($self->{logged_in} = shift) {
            # set session parameter
            $self->_session->param("~logged-in", 1);
        }
        else {
            # clear session parameter
            $self->_session->clear(["~logged-in"]);
        }
        $self->_debug("(re)set logged_in: ", $self->{logged_in});
    }
    
    # return internal flag
    return $self->{logged_in};
}

###########################################################

sub _url {
    
    my $self = shift;
    
    return $self->{url};
}

###########################################################
###
### end of code, module documentation below
###
###########################################################

1;
__END__

=head1 NAME

CGI::Session::Auth - Authenticated sessions for CGI scripts


=head1 ABSTRACT

CGI::Session::Auth is a Perl class that provides the necessary
functions for authentication in CGI scripts. It uses CGI::Session
for session management and supports several backends for
user and group data storage.


=head1 SYNOPSIS

  use CGI;
  use CGI::Session;
  use CGI::Session::Auth;

  # CGI object for headers, cookies, etc.
  my $cgi = new CGI;

  # CGI::Session object for session handling
  my $session = new CGI::Session(undef, $cgi, {Directory=>'/tmp'});

  # CGI::Session::Auth object for authentication
  my $auth = new CGI::Session::Auth({ CGI => $cgi, Session => $session });
  $auth->authenticate();
  
  # check if visitor has already logged in
  if ($auth->loggedIn) {
      showSecretPage;
  }
  else {
      showLoginPage;
  }


=head1 DESCRIPTION

CGI::Session::Auth offers an alternative to HTTP
authentication. Its goal is to integrate the authentication
process into the web application as seamless as possible while keeping
the programming interface simple.

Users can authenticate themselves by entering their user
name and password into a login form. This is the most common way
of authenticating a web site visitor.

Alternatively, a user can automatically be authenticated by his IP address.
This is useful when authorized users can't be bothered to log in manually
but can be identified by a range of fixed IP addresses.

CGI::Session::Auth manages a profile for every user account,
containing his user name, his password and his user id. The user profile may
contain additional fields for arbitrary data.

B<IMPORTANT:> The class CGI::Session::Auth itself is only an abstract base class with
no real storage backend (only the user 'guest' with password 'guest'
may log in). You have to derive a child class that implements its own _login() method
where the actual authentication takes place.


=head1 METHODS


=head2 new(\%parameters)

This is the class constructor. The hash referenced by C<\%parameters> must contain
the following key/value pairs:

=over 4

=item CGI

A reference to an CGI or CGI::Simple object.

=item Session

A reference to an CGI::Session object.

=back

Additionally, the following optional parameters are possible:

=over 4

=item IPAuth

Try to authenticate the visitor by his IP address. (Default: 0)

=item LoginVarPrefix

By default, CGI::Session::Auth expects the username and password of
the visitor to be passed in the form variables 'log_username' and
'log_password'. To avoid conflicts, the prefix 'log_' can be altered
by this parameter.

=item Log

Set to 1 to enable logging. CGI::Session::Auth expects an initialized Log::Log4perl 
module and gets its logger object calling Log::Log4perl->get_logger('CGI::Session::Auth').

=back


=head2 authenticate()

This method does the actual authentication. It fetches session information to
determine the authentication status of the current visitor and further checks
if form variables from a proceeding login form have been set and eventually
performs a login attempt.

This login attempt is done by calling the method _login() (see below).

If authentication succeeded neither by session data nor login information, and
the parameter C<IPAuth> is set to a true value, it tries to authenticate the
visitor by his IP address.


=head2 _login()

This virtual method performs the actual login attempt by comparing the login
form data the visitor sent with some local user database. The _login method of
the base class CGI::Session::Auth only knows the user 'guest' with password
'guest'.

To access a real user database, you have to use a subclass that modifies the
_login method appropriately. See the modules in the Auth/ subdirectory.


=head2 sessionCookie()

For the session to be persistent across page requests, its session ID has to be
stored in a cookie. This method returns the correct cookie (as generated by CGI::cookie()),
but it remains the duty of the CGI application to send it.


=head2 loggedIn()

Returns a boolean value representing the current visitors authentication
status.


=head2 logout()

Discards the current visitors authentication status.


=head2 hasUsername($username)

Checks if a certain user is logged in.


=head2 isGroupMember($groupname)

Checks if the current user is a member of a certain user group.


=head2 profile($key [, $value])

Returns the user profile field identified by C<$key>. If C<$value> is given,
it will be stored in the respective profile field first.


=head2 _encpw($password)

Returns a cryptographic hash version of the password argument. If you want to
store passwords in encrypted form for security reasons, use this function when
you store the password and when you compare the stored password with the input
submitted by the user.


=head1 SUPPORT

For further information regarding this module, please visit the 
project website at https://launchpad.net/perl-cgi-session-auth.


=head1 BUGS

Please report all bugs via the issue tracking on the project website.

Assistance in the development of this modules is encouraged and
greatly appreciated.


=head1 SEE ALSO

L<CGI::Session>
L<CGI::Application::Plugin::Session>


=head1 AUTHOR

Jochen Lillich, E<lt>geewiz@cpan.orgE<gt>


=head1 CONTRIBUTORS

These people have helped in the development of this module:

=over

=item Cees Hek
=item Daniel Brunkhorst
=item Gregory Ramsperger
=item Jess Robinson
=item Simon Rees
=item Roger Horne
=item Oliver Paukstadt
=item Jonathon Wyza
=item Hugh Esco

=back


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2010 by Jochen Lillich

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

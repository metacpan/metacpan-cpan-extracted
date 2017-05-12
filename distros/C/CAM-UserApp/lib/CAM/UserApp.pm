package CAM::UserApp;

=head1 NAME

CAM::UserApp - Extension of CAM::App to support web login

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DESCRIPTION

CAM::UserApp provides generic session-based login capabilities.  It
supports login, state maintenance and password changing in a framework
that supports either SOAP or cookie-based HTML, among other
possibilities.

CAM::UserApp is not complete by itself.  Some of its methods must be
implemented by a subclass.  In particular, retrieveUser() must be
supplied.  In an HTML or other human-interaction environment, the
offerLogin() and offerChangePassword() methods should be implemented.
Others are optional, and are described below.

=head1 SYNOPSIS

A nearly-complete example subclass:

    package MyApp;
    use CAM::UserApp;
    our @ISA=qw(CAM::UserApp);
    
    sub retrieveUser {
      my ($self, $user, $pass) = @_;
      # (do some SQL lookup perhaps)
      my $user = Some::Pkg->new($user, $pass);
      return $user;
    }
    
    sub offerLogin {
      my ($self, %args) = @_;
      print $self->header();
      $self->getTemplate("login.tmpl", 
                         error=>$args{error},
                         passthru=>$args{passthru})
           ->print();
    }
    
    sub offerChangePassword {
      my ($self, %args) = @_;
      print $self->header();
      $self->getTemplate("changePass.tmpl", error=>$args{error})
           ->print();
    }
    1;

A CGI script that uses CAM::UserApp through that subclass:

    #!perl
    use Config;
    use MyApp;
    my $app = MyApp->new(config => Config->new());
    $app->authenticate() or exit(0);
    my $user = $app->getUser();
    if ($app->getCGI()->param('logout')) {
       $app->deauthenticate();
       exit(0);
    } elsif ($app->getCGI()->param('changepass')) {
       $app->changePassword($user->getUsername()) or exit(0);
    }
    
    print $app->header();
    print "Welcome " . $user->getName() . "!\n";
    ...

Note that the class for $user is not defined here.  You must build
that yourself.  The new() and getName() and getUsername() methods
shown above are for example only.

Note that authentication is performed separately from initialization
for the sake of applications where login is optional.  If your
application requires login, we recommend that your CAM::UserApp
subclass include methods like the following in addition to those shown
in the subclass above.

    use Config;
    sub new {
      my $pkg = shift;
      return $pkg->SUPER::new(config => Config->new(), 
                              needPassword => 1, @_);
    }
    sub init {
      my $self = shift;
      $self->SUPER::init() or return undef;
      $self->authenticate() or exit(0);
      if ($app->getCGI()->param('logout')) {
         $app->deauthenticate();
         exit(0);
      } elsif ($app->getCGI()->param('changepass')) {
         $app->changePassword($app->getUser()->getUsername()) or exit(0);
      }
      return $self;
    }

Thus your CGI could look as simple as:

    #!perl
    use MyApp;
    my $app = MyApp->new();
    print $app->header();
    print "Welcome " . $app->getUser()->getName() . "!\n";
    ...

while still including full login support.

=cut

#--------------------------------#

require 5.005_62;
use strict;
use warnings;
use CAM::App;

our @ISA = qw(CAM::App);
our $VERSION = '1.01';

#--------------------------------#

=head1 CLASS METHODS

=over 4

=cut

#--------------------------------#

=item usernameCGIKey

=item passwordCGIKey

=item password1CGIKey

=item password2CGIKey

Simple accessors that return the CGI parameter names used to input
login details.  These are provided so they can be overrided by
subclasses.  The defaults are:

  usernameCGIKey  "username"
  passwordCGIKey  "password"
  password1CGIKey "password1"
  password2CGIKey "password2"

username and password are used for input to authenticate() while
password1, password2 and (optionally) password are used for
changePassword().

=cut

sub usernameCGIKey { "username" }
sub passwordCGIKey { "password" }
sub password1CGIKey { "password1" }
sub password2CGIKey { "password2" }

#--------------------------------#

=item new [argument list...]

Overrides the superclass constructor to add boolean settings.  These
settings are used in the authenticate() and changePassword() methods
below.  Both of those methods allow callers to override this value
directly if desired.

All other arguments are passed on the to the superclass constructor.

  interactive => boolean (default: true)

If true, login or change password failures yield calls to offerLogin()
or offerChangePassword(), respectively.  If false, these calls are
skipped.  The equivalent effect to interactive = false can be achieved
by using a no-op offerLogin() or offerChangePassword(), which are in
fact the default behaviors for those functions.

  useCGI => boolean (default: true)

Specifies whether the CGI parameters should be consulted for username
and password values, if any.  CGI values override session values.

  useSession => boolean (default: true)

Specifies whether the session record should be consulted for username
and password values, if any.

  needPassword => boolean (default: false)

Specifies whether the user has to enter their old password before a
new one can be set in changePassword().  While it defaults to the lax
'false' state, I recommend you set this to true for interactive
applications!

=cut

sub new
{
   my $pkg = shift;
   my %params = (@_);

   my $self = $pkg->SUPER::new(%params);
   $self->{useCGI}       = exists $params{useCGI}       ? $params{useCGI}       : 1;
   $self->{useSession}   = exists $params{useSession}   ? $params{useSession}   : 1;
   $self->{needPassword} = exists $params{needPassword} ? $params{needPassword} : 0;
   $self->{interactive}  = exists $params{interactive}  ? $params{interactive}  : 1;
   return $self;
}
#--------------------------------#

=back

=head1 INSTANCE METHODS

=over 4

=cut

#--------------------------------#

=item retrieveUser USERNAME, PASSWORD

This method MUST be overridden by a subclass, or authenticate() will
never succeed.  It should return an object for the specified username
and password, or undef if there is no such user.  The object can be of
any class as long as: 1) it is blessed, 2) it has a
recordPassword($password) method that can be called from our
changePassword() function.  Note that this method MAY be called
multiple times during a session, so don't do hit counting in here.

=cut

sub retrieveUser
{
   my $self = shift;
   my $username = shift;
   my $password = shift;

   my $user;
   
   # Do something here:
   #   Get a user object (likely a database record)
   #   Make a record of the login?
   #   Tweak the user object?
   # Return undef if retrieval fails

   # The returned object should have a recordPassword() method

   return $user;
}
#--------------------------------#

=item authenticate

Validate a login.  Returns a boolean indicating success.  Most
applications should abort upon receiving a false response.  If the
login fails, or if username/password parameters are missing, the
offerLogin() method is called before false is returned.  For this
method to succeed, the retrieveUser() method MUST be implemented by a
subclass.  After success, the getUser() method will return the cached
result from retrieveUser().

Optional arguments:

  username => string (default: undef)
  password => string (default: undef)

Values to use for login.  Overrides CGI and session values.

  useCGI => boolean
  useSession => boolean
  interactive => boolean

These values, if not passed as arguments, are inherited from the
CAM::UserApp instance.

=cut

sub authenticate
{
   my $self = shift;
   my %args = (@_);

   my $session;
   my $cgi;
   my $passthru = "";

   foreach my $key ("useCGI", "useSession", "interactive")
   {
      $args{$key} = $self->{$key} unless (exists $args{$key});
   }

   if ($args{useCGI})
   {
      $cgi = $self->getCGI();
      $args{username} ||= $cgi->param($self->usernameCGIKey());
      $args{password} ||= $cgi->param($self->passwordCGIKey());
      if ($args{interactive})
      {
         foreach my $key ($cgi->param)
         {
            next if ($key eq $self->usernameCGIKey() ||
                     $key eq $self->passwordCGIKey());
            my $hkey = $cgi->escapeHTML($key);
            foreach my $value ($cgi->param($key))
            {
               $value = "" if (!defined $value);
               my $hvalue = $cgi->escapeHTML($value);
               $passthru .= qq[<input type="hidden" name="$hkey" value="$hvalue">];
            }
         }
      }
   }
   if ($args{useSession})
   {
      $session = $self->getSession();
      unless ($session->isNewSession())
      {
         $args{username} ||= $session->get("username");
         $args{password} ||= $session->get("password");
      }
   }

   unless ($args{username} || $args{password})
   {
      if ($args{interactive})
      {
         $self->offerLogin(passthru => $passthru);
      }
      return undef;
   }

   unless ($args{username})
   {
      if ($args{interactive})
      {
         $self->offerLogin(error => "Please enter your username",
                           passthru => $passthru);
      }
      return undef;
   }

   unless ($args{password})
   {
      if ($args{interactive})
      {
         $self->offerLogin(error => "Please enter your password",
                           passthru => $passthru);
      }
      return undef;
   }

   my $user = $self->retrieveUser($args{username}, $args{password});
   unless ($user)
   {
      if ($args{interactive})
      {
         $self->offerLogin(error => "Login failed",
                           passthru => $passthru);
      }
      return undef;
   }

   $self->{User} = $user;

   if ($session)
   {
      $session->set(username => $args{username},
                    password => $args{password});
   }

   return $self;
}

#--------------------------------#

=item getUser

Returns the User object obtained from authenticate().  If
authentication fails, or is never attempted, this method will return
undef.

=cut

sub getUser
{
   my $self = shift;
   return $self->{User};
}
#--------------------------------#

=item deauthenticate

Logs out an authenticated user.  If a session is present, it is wiped.
After this, the getUser() will return undef.  This method returns
self.

Optional arguments:

  useSession => boolean (default: true)

Specifies whether the session record should be cleared.

  interactive => boolean (default: true)

If true, the offerLogin() method is called at the end of
deauthentication.

=cut

sub deauthenticate
{
   my $self = shift;
   my %args = (@_);

   $args{useSession}  = 1 unless (exists $args{useSession});
   $args{interactive} = 1 unless (exists $args{interactive});

   if ($args{useSession})
   {
      my $session = $self->getSession();
      if ($session)
      {
         $session->clear();
      }
   }
   delete $self->{User};
   if ($args{interactive})
   {
      $self->offerLogin();
   }
   return $self;
}

#--------------------------------#

=item changePassword

Change the users password.  The user must already be authenticated.
If the new password is missing or invalid or if the retyped value does
not match, this calls offerChangePassword and returns undef.  If the
needPassword flag is set, the old password must be entered.  It will
be validated via the retrieveUser() method.

Optional arguments:

  username  => string (default: undef)
  password  => string (default: undef)

Values to use for authentication if needPassword is true.  Overrides
CGI values.

  password1 => string (default: undef)
  password2 => string (default: undef)

Values to use for the new password and password verification.
Overrides CGI values.

  interactive => boolean
  useCGI => boolean
  useSession => boolean
  needPassword => boolean

These values, if not passed as arguments, are inherited from the
CAM::UserApp instance.

=cut

sub changePassword
{
   my $self = shift;
   my %args = (@_);

   foreach my $key ("useCGI", "useSession", "interactive", "needPassword")
   {
      $args{$key} = $self->{$key} unless (exists $args{$key});
   }

   my $user = $self->getUser();
   my $cgi;

   if ($args{useCGI})
   {
      $cgi = $self->getCGI();
      $args{password} ||= $cgi->param($self->passwordCGIKey());
      $args{password1} ||= $cgi->param($self->password1CGIKey());
      $args{password2} ||= $cgi->param($self->password2CGIKey());
   }

   unless ($args{password1} || $args{password2})
   {
      $self->offerChangePassword();
      return undef;
   }

   unless ($args{password1} && $args{password2})
   {
      $self->offerChangePassword(error => "Please fill in all password fields");
      return undef;
   }

   if ($args{needPassword})
   {
      unless ($args{password})
      {
         $self->offerChangePassword(error => "Please fill in all password fields");
         return undef;
      }
      unless ($args{username})
      {
         $self->offerChangePassword(error => "Error: no username found");
         return undef;
      }
      unless ($self->retrieveUser($args{username}, $args{password}))
      {
         $self->offerChangePassword(error => "Incorrect password");
         return undef;
      }
   }

   if ($args{password1} ne $args{password2})
   {
      $self->offerChangePassword(error => "The passwords you have entered do not match");
      return undef;
   }

   my $password = $args{password1}; # shorthand
   unless ($self->validateNewPassword($password))
   {
      $self->offerChangePassword(error => "Invalid password, please try again");
      return undef;
   }

   unless ($user->can("recordPassword") && $user->recordPassword($password))
   {
      $self->offerChangePassword(error => "Unable to record your new password");
      return undef;
   }

   if ($args{useSession})
   {
      # Note! We DO NOT want to create a new session here, so we don't
      # use the getSession() method.  If there is no session, well, so
      # be it.

      my $session = $self->{session};
      if ($session)
      {
         $session->set(password => $password);
      }
   }

   return $self;
}
#--------------------------------#

=item offerLogin

Display an interactive login.  By default, this method is a no-op.
Interactive subclasses should override this method.  The return value
of this method is not used.  A sample implementation is presented in
the Synopsis above.

Optional arguments:

  error => string

Indicates a reason why this method has been called, like "Login
failure".  On a fresh login, this argument is absent.

  passthru => string

An accumulation of CGI parameters passed to this program, in the form
of '<input type=hidden name=key value=value>' for each parameter.
Implementations are welcome to ignore this, but they should pass it
via an HTML form if they want to make the login be 'transparent',
i.e., if the program should go back to whatever it was doing before
when login is successful login.

Here's an example HTML template file for use with the offerLogin()
implementation in the Synopsis above, using these parameters:

  <html><head><title>Login</title></head><body>
  <form action="::myURL::" method="post">
  ??error?? <span style="color:red">::error::</span> <br> ??error??
  Username: <input type="text" name="username"><br>
  Password: <input type="password" name="password"><br>
  <input type="submit" value="Login">
  ::passthru::
  </form></body></html>

=cut

sub offerLogin
{
   my $self = shift;
   my %args = (@_);

   # do nothing unless subclass overrides
}
#--------------------------------#

=item offerChangePassword

Display an interactive password change screen.  By default, this
method is a no-op, so interactive subclasses should override this
method.  The return value of this method is not used.  A sample
implementation is presented in the Synopsis above.

Optional arguments:

  error => string

Indicates a reason why this method has been called, like "Passwords do
not match".  On first hit, this argument is absent.

Here's an example HTML template file for use with the
offerChangePassword() implementation in the Synopsis above, using
this parameters:

  <html><head><title>Change Password</title></head><body>
  <form action="::myURL::" method="post">
  ??error?? <span style="color:red">::error::</span> <br> ??error??
  Old Password: <input type="password" name="password"><br>
  New Password: <input type="password" name="password1"><br>
  Retype Password: <input type="password" name="password2"><br>
  <input type="submit" value="Submit">
  </form></body></html>

=cut

sub offerChangePassword
{
   my $self = shift;
   my %args = (@_);

   # do nothing unless subclass overrides
}
#--------------------------------#

=item validateNewPassword PASSWORD

Performs simple checks on the validity of a new password.  This
implementation only checks that the password is defined and not the
null string.  Subclasses may implement more rigorous checks.

=cut

sub validateNewPassword
{
   my $self = shift;
   my $password = shift;

   return undef unless (defined $password && $password ne "");

   return $self;
}
#--------------------------------#

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

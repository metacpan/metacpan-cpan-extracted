package Apache::SiteControl::User;

use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = "1.0";

# This object represents a transient view of a persistent user. The UserManager
# is responsible for loading/saving these things.
sub new($$$$) {
   my $proto = shift;
   my $username = shift;
   my $sessionid = shift;
   my $usermanager = shift;
   my $class = ref($proto) || $proto;
   my $this  = { username => $username,
                 sessionid => $sessionid,
                 manager => $usermanager, 
                 attributes => {} };
   bless ($this, $class);
   return $this;
}

sub getUsername
{
   my $this = shift;
   return $this->{username};
}

# user, request, name, value
sub setAttribute
{
   my $this = shift;
   my $r = shift;
   my $name = shift;
   my $value = shift;

   $this->{attributes}{$name} = $value;
   eval("$this->{manager}" . '->saveAttribute($r, $this, $name)');
   if($@) {
      $r->log_error("ERROR! FAILED TO SAVE ATTRIBUTE. SESSION WILL NOT WORK: $@");
   }
}

sub getAttribute
{
   my $this = shift;
   my $name = shift;

   return $this->{attributes}{$name} if defined($this->{attributes}{$name});

   return undef;
}

# user object, apache request
sub logout
{
   my $this = shift;
   my $r = shift;

   if(!defined($this) || !defined($r)) {
      croak "INVALID CALL TO LOGOUT. You forgot to use OO syntax, or you forgot to pass the request object.";
   }
   eval("$this->{manager}" . '->invalidate($r, $this)');
   if($@) {
      $r->log_error("Logout failed: $@");
   }
}

1;

__END__

=head1 NAME

Apache::SiteControl::User - User representations

=head2 SYNOPSIS

   my $user = Apache::SiteControl->getCurrentUser($r);

   # $r is the apache request object

   # Checking out the user's name:
   if($user->getUsername eq 'sam') { ... }

   ...

   # Working with attributes (session persistent data)
   my $ssn = $user->getAttribute('ssn');
   $user->setAttribute($r, 'ssn', '333-555-6666');

   # Removing/invalidating session for the user
   $user->logout($r);

=head2 DESCRIPTION

The SiteControl system has a base concept of a user which includes the user's
name, persistent attributes (which are persistent via session), and support
for user logout.

It is assumed that you will be working from mod_perl, and some of the methods
require an Apache request object. The request object is used by some methods to
coordinate access to the actual session information in the underlying system
(for storing attributes and implementing logout).

User objects are created by a factory (by default
Apache::SiteControl::UserFactory), so if you subclass User, you must understand
the complete interaction between the factory (which is responsible for
interfacing with persistence), the SiteControl, etc.

The default implementation of User and UserFactory use AuthCookie to manage the
sessions, and Apache::Session::File to store the various details about a user
to disk.

If you are using Apache::SiteControl::User and Apache::SiteControl::UserFactory
(the default and recommended), then you should configure the following
parameters in your apache configuration file:

   # This is where the session data files will be stored
   SiteControlSessions directory_name
   # This is where the locks will be stored
   SiteControlLocks directory_name

These two directories should be different, and should be readable and writable
by the apache daemon only. They must exist before trying to use SiteControl.

=head1 METHODS

=over 8

=item B<getUsername> Get the name that the current user used to log in.

=item B<getAttribute($name)> Get the value of a previously stored attribute. Returns undef is there is no value.

=item B<setAttribute($request, $name, $value)> Add an attribute
(scalar data only) to the current session. The current apache request object is
required (in order to figure out the session). Future versions may support more
complex storage in the session. This attribute will stay associated with this
user until they log out.

=item B<logout($request)> Log the user out. If you do not pass the current apache request, then this method will log an error to the apache error logs, and the user's session will continue to exist. 

=back

=head1 SEE ALSO

Apache::SiteControl::UserFactory, Apache::SiteControl::ManagerFactory,
Apache::SiteControl::PermissionManager, Apache::SiteControl

=head1 AUTHOR

This module was written by Tony Kay, E<lt>tkay@uoregon.eduE<gt>.

=head1 COPYRIGHT AND LICENSE

This modules is covered by the GNU public license.

=cut

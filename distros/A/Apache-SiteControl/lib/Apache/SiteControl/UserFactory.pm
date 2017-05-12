package Apache::SiteControl::UserFactory;

use 5.008;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Apache::SiteControl::User;
use Crypt::CBC;

our $VERSION = "1.0";

our $engine;
our $encryption_key;

sub init_engine
{
   my $cipher = shift;
   my $key = shift;

   if(!defined($engine)) {
      $engine = Crypt::CBC->new({ key => $key, cipher => $cipher });
   }
}

# Params: Apache request, username, password, other credentials...
sub makeUser
{
   my $this = shift;
   my $r = shift;
   my $username = shift;
   my $password = shift;
   my @other_cred = @_;
   my $sessiondir = $r->dir_config("SiteControlSessions") || "/tmp";
   my $lockdir = $r->dir_config("SiteControlLocks") || "/tmp";
   my $debug = $r->dir_config("SiteControlDebug") || 0;
   my $savePassword = $r->dir_config("UserObjectSavePassword") || 0;
   my $cipher = $r->dir_config("UserObjectPasswordCipher") || "CAST5";
   my $key = $r->dir_config("UserObjectPasswordKey") || $encryption_key || "A not very secure key because the admin forgot to set it.";
   my $saveOther = $r->dir_config("UserObjectSaveOtherCredentials") || 0;
   my $factory = $r->dir_config("SiteControlUserFactory") || "Apache::SiteControl::UserFactory";
   my $user = undef;
   my %session;
   my $usermap;
   my $session_removed = 0;

   $r->log_error("encryption engine using key: $key") if $debug;
   init_engine($cipher, $key) if($savePassword);

   # Proper steps:
   # 1. Check to see if session already exists for user. If so, delete it.
   # 2. Create new session for user and populate it.
   # 3. Return the new user object.
   $r->log_error("Making user object for $username.") if $debug;
   eval {
      $usermap = $this->_getUsermap($r);
      $r->log_error("Login process got user map: " . Dumper($usermap)) if $debug;
      if(defined($usermap) && defined($usermap->{$username})) {
         $r->log_error("$username is logging in, and already had a session $usermap->{$username}{_session_id}. Removing old session.");
         $session_removed = 1;
         eval {
            tie %session, 'Apache::Session::File', 
               $usermap->{$username}{_session_id}, {
                  Directory => $sessiondir,
                  LockDirectory => $lockdir
               };
            tied(%session)->delete;
         };
         if($@) {
            $r->log_error("Could not delete old session: $@");
         }
      }
      tie %session, 'Apache::Session::File', undef, 
         {
            Directory => $sessiondir,
            LockDirectory => $lockdir
         };
      $user = new Apache::SiteControl::User($username, $session{_session_id}, $factory);
      $session{username} = $username;
      $session{manager} = $factory;
      $session{attr_password} = $engine->encrypt($password) if($savePassword);
      $session{attr_session_removed} = $session_removed;
      if(@other_cred && $saveOther) {
         my $i = 2;
         for my $c (@other_cred) {
            $r->log_error("Saving extra credential_$i with value $c") if $debug;
            $session{"attr_credential_$i"} = $c;
            $i++;
         }
      }
      $r->log_error("Created user: " . Dumper($user)) if $debug;
   };
   if($@) {
      $r->log_error("Problem making new user object: $@");
      return undef;
   }

   # Note: this is a half-baked user, but the controller only needs the session
   # id. It might be better to return the result of findUser instead.
   return $user;
}

# Params: apache request, session_key
sub findUser
{
   my $this = shift;
   my $r = shift;
   my $ses_key = shift;
   my $sessiondir = $r->dir_config("SiteControlSessions") || "/tmp";
   my $lockdir = $r->dir_config("SiteControlLocks") || "/tmp";
   my $debug = $r->dir_config("SiteControlDebug") || 0;
   my $savePassword = $r->dir_config("UserObjectSavePassword") || 0;
   my $cipher = $r->dir_config("UserObjectPasswordCipher") || "CAST5";
   my $key = $r->dir_config("UserObjectPasswordKey") || $encryption_key || "A not very secure key because the admin forgot to set it.";
   my %session;
   my $user;

   $r->log_error("encryption engine using key: $key") if $debug;
   init_engine($cipher, $key) if($savePassword);

   eval {
      tie %session, 'Apache::Session::File', $ses_key, {
         Directory => $sessiondir,
         LockDirectory => $lockdir
         };
      # FIXME: Document the possible problems with changing user factories when
      # persistent sessions already exist.
      $user = new Apache::SiteControl::User($session{username}, $ses_key, $session{manager});
      for my $key (keys %session) {
         next if $key !~ /^attr_/;
         my $k2 = $key;
         $k2 =~ s/^attr_//;
         if($k2 eq 'password') {
            $user->{attributes}{$k2} = $engine->decrypt($session{$key});
         } else {
            $user->{attributes}{$k2} = $session{$key};
         }
      }
      $r->log_error("Restored user: " . Dumper($user)) if $debug;
   };
   if($@) {
      # This method should fail for new logins (or login after logout), so
      # failing to find the user is not considered a "real" error
      $r->log_error("Failed to find a user with cookie $ses_key.") if $debug;
      return undef;
   }

   return $user;
}

# Apache request, user object (not name)
sub invalidate
{
   my $this = shift;
   my $r = shift;
   my $userobj = shift;
   my $debug = $r->dir_config("SiteControlDebug") || 0;
   my $sessiondir = $r->dir_config("SiteControlSessions") || "/tmp";
   my $lockdir = $r->dir_config("SiteControlLocks") || "/tmp";
   my %session;

   if(!$userobj->isa("Apache::SiteControl::User") || !defined($userobj->{sessionid})) {
      $r->log_error("Invalid user object passed to saveAttribute. Cannot remove user.");
      return 0;
   }

   $r->log_error("Logging out user: " . $userobj->getUsername) if $debug;
   eval {
      tie %session, 'Apache::Session::File', $userobj->{sessionid}, {
         Directory => $sessiondir,
         LockDirectory => $lockdir
         };

      tied(%session)->delete;
      $r->log_error("Done with logout.") if $debug;
   };
   if($@) {
      $r->log_error("Could not delete user (logout): $@");
   }
}

# Apache request, user object, attribute name
sub saveAttribute
{
   my $this = shift;
   my $r = shift;
   my $userobj = shift;
   my $name = shift;
   my $debug = $r->dir_config("SiteControlDebug") || 0;
   my $sessiondir = $r->dir_config("SiteControlSessions") || "/tmp";
   my $lockdir = $r->dir_config("SiteControlLocks") || "/tmp";
   my %session;

   if(!$userobj->isa("Apache::SiteControl::User") || !defined($userobj->{sessionid})) {
      $r->log_error("Invalid user object passed to saveAttribute. Attribute not saved.");
      return 0;
   }

   eval {
      tie %session, 'Apache::Session::File', $userobj->{sessionid}, {
         Directory => $sessiondir,
         LockDirectory => $lockdir
         };

      $r->log_error("Saving attribute $name = " .
         $userobj->getAttribute($name) . 
         "using Apache::Session::File.") if $debug;
      $session{"attr_$name"} = $userobj->getAttribute($name);
      untie %session;
   };
   if($@) {
      $r->log_error("Failed to save user attribute: $@");
      return 0;
   }
}

# Internal method for this implementation (using session files)
# in: Apache request object
sub _getUsermap
{
   my $this = shift;
   my $r = shift;
   my $sessiondir = $r->dir_config("SiteControlSessions") || "/tmp";
   my $lockdir = $r->dir_config("SiteControlLocks") || "/tmp";
   my $debug = $r->dir_config("SiteControlDebug") || 0;
   my %usermap;

   eval {
   my %session;

   my @files = <$sessiondir/[0-9a-f]*>;
   my @sessions = grep { s#^.*/([^/]*)$#$1# } @files;
   my $username;

   $r->log_error("Current sessions: @sessions") if $debug;
   for my $id (@sessions)
   {
      next if $id !~ /^[0-9a-f]{20,}/;
      tie %session, 'Apache::Session::File', $id, {
         Directory => $sessiondir,
         LockDirectory => $lockdir
         };
      $username = $session{username};
      if(!defined($username)) {
         $r->log_error("Session $session{_session_id} does not have a username...deleting");
         tied(%session)->delete;
         next;
      }
      if(defined($usermap{$username})) {
         # last modify time of session we saw
         my $timea = (stat("$sessiondir/$usermap{$username}{_session_id}"))[9];
         # last modify time of this session
         my $timeb = (stat("$sessiondir/$id"))[9];
         $r->log_error("User $username has duplicate session! Expiring old session");
         if($timea < $timeb) {
            # The one we saw earlier is older. Delete it.
            untie %session;
            tie %session, 'Apache::Session::File', 
               $usermap{$username}{_session_id}, {
               Directory => $sessiondir,
               LockDirectory => $lockdir
               };
            tied(%session)->delete;
            redo; # redo this loop so we record the more better one ;)
         } else {
            # The one we are looking at is older...delete it and go on.
            tied(%session)->delete;
            next;
         }
      }
      $usermap{$username} = {};
      # Copy the session into our usermap
      for my $key (keys %session) {
         $usermap{$username}{$key} = $session{$key};
      }
      untie %session;
   }
   $r->log_error("Current user map : " .  Dumper(\%usermap)) if $debug;

   };
   if($@) {
      $r->log_error("Failure in _getUsermap: $@");
      return undef;
   }

   return { %usermap };
}

1;

__END__

=head1 NAME

Apache::SiteControl::UserFactory - User factory/persistence

=head1 DESCRIPTION

This class is responsible for creating user objects (see
Apache::SiteControl::User) and managing the interfacing of those objects with a
persistent session store.  The default implementation uses
Apache::Session::File to store the various attributes of the user to disk.

If you want to do your own user management, then you should leave the User
class alone, and subclass only this factory. The following methods are
required:

=over 3

=item makeUser($$) 

This method is called with the Apache Request object, username, password, and
all other credential_# fields from the login form.  It must create and return
an instance of Apache::SiteControl::User (using new...See User), and store that
information (along with the session key stored in cookie format in the request)
in some sort of permanent storage.  This method is called in response to a
login, so it should invalidate any existing session for the given user name (so
that a user can be logged in only once).  This method must return the key to
use as the browser session key, or undef if it could not create the user.

=item findUser($$) 

This method is passed the apache request and the session key (which you defined
in makeUser).  This method is called every time a "logged in" user makes a
request. In other words the user objects are not persistent in memory (each
request gets a new "copy" of the state). This method uses the session key
(which was stored in a browser cookie) to figure out what user to restore. The
implementation is required to look up the user by the session key, recreate a
Apache::SiteControl::User object and return it. It must restore all user
attributes that have been saved via saveAttribute (below). 

=item invalidate($$) 

This method is passed the apache request object and a previously created user
object. It should delete the user object from permanent store so that future
request to find that user fails unless makeUser has been called to recreate it.
The session ID (which you made up in makeUser) is available from
$user->{sessionid}.

=item saveAttribute($$$)  

This method is automatically called whenever a user has a new attribute value.
The incoming arguments are the apache request, the user object, and the name of
the attribute to save (you can read it with $user->getAttribute($name)). This
method must save the attribute in a such a way that later calls to findUser
will be able to restore the attribute to the user object that is created. The
session id you created for this user (in makeUser) is available in
$user->{sessionid}.

=back

=head1 Apache Config Directives

The following is a list of configuration variables that can be set with
apache's PerlSetVar to configure the behavior of this class:

=over 3

=item  SiteControlDebug  (default 0): 

Debug mode

=item  SiteControlLocks  (default /tmp): 

Where the locks are stored

=item  SiteControlSessions (default /tmp): 

Where the session data is stored

=item  SiteControlUserFactory (default: Apache::SiteControl::UserFactory)

An implementation like this module.

=item  UserObjectSaveOtherCredentials (default: 0)

Indicates that other form data from the login screen (credential_2,
credential_3, etc.) should be saved in the session data. The keys will be
credential_2, etc.  name of the user factory to use when making user objects.
These are useful if your web application has other login choices (i.e. service,
database, etc.) that you need to know about at login.

=item  UserObjectSavePassword (default 0)

Indicates that the password should be saved in the local session data, so that
it is available to other parts of the web app (and not just the auth system).
This might be necessary if you are logging the user in and out of services on
the back end (like in webmail and database apps).

=item  UserObjectPasswordCipher (default CAST5)

The CBC cipher used for encrypting the user passwords in the session files (See
Crypt::CBC for info on allowed ciphers...this value is passed directly to
Crypt::CBC->new). If you are saving user passwords, they will be encrypted when
stored in the apache session files. This gives a little bit of added security,
and makes the apache config the only sensitive file (since that is where you
configure the key itself) instead of every random session file that is laying
around on disk. 
      
There is a global variable in this package called $encryption_key, which will
be used if this variable is not set. The suggested method is to set the
encryption key during server startup using a random value (i.e. from
/dev/random), so that all server forks will inherit the value.
      
=item  UserObjectPasswordKey

The key to use for encryption of the passwords in the session files. See
UserObjectPasswordCipher above.

=back

=head1 SEE ALSO

Apache::SiteControl::User, Apache::SiteControl::PermissionManager,
Apache::SiteControl::Rule, Apache::SiteControl

=head1 AUTHOR

This module was written by Tony Kay, E<lt>tkay@uoregon.eduE<gt>.

=head1 COPYRIGHT AND LICENSE

Apache::SiteControl is covered by the GPL.

=cut

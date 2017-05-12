package Apache::SiteControl;

use 5.008;
use strict;
use warnings;
use Carp;
use Apache::AuthCookie;
use Apache::Session::File;

our $VERSION = "1.01";

use base qw(Apache::AuthCookie);

our %managers = ();

sub getCurrentUser
{
   my $this = shift;
   my $r = shift;
   my $debug = $r->dir_config("SiteControlDebug") || 0;
   my $factory = $r->dir_config("SiteControlUserFactory") || "Apache::SiteControl::UserFactory";
   my $auth_type = $r->auth_type;
   my $auth_name = $r->auth_name;
   my ($ses_key) = ($r->header_in("Cookie") || "") =~ /$auth_type\_$auth_name=([^;]+)/;

   $r->log_error("Session cookie: " . ($ses_key ? $ses_key:"UNSET")) if $debug;
   $r->log_error("Loading module $factory") if $debug;
   eval "require $factory" or $r->log_error("Could not load $factory: $@");
   $r->log_error("Using user factory $factory") if $debug;
   my $username = $r->connection->user();
   return undef if(!$username);

   $r->log_error("user name is $username") if $debug;
   my $user = undef;

   $factory = '$user' . " = $factory" . '->findUser($r, $ses_key)';
   $r->log_error("Evaluating: $factory") if $debug;
   eval($factory) or $r->log_error("Eval failed: $@");

   $r->log_error("Got user object: $user") if $debug && defined($user);
   return defined($user) ? $user : 0;
}

sub getPermissionManager
{
   my $this = shift;
   my $r = shift;

   my $debug = $r->dir_config("SiteControlDebug") || 0;
   my $name = $r->dir_config("AuthName") || "default";
   $r->log_error("AuthName is not set! Using 'default'.") if $name eq "default";

   return $managers{$name} if(defined($managers{$name}) && $managers{$name});
   $r->log_error("Building manager") if $debug;

   my $factory = $r->dir_config("SiteControlManagerFactory");
   $r->log_error("Manager Factory not set!") if !defined($factory);

   return undef if !defined($factory);
   $r->log_error("Loading module $factory") if $debug;
   eval "require $factory" or $r->log_error("Could not load $factory: $@");

   $factory = '$managers{$name}' . " = $factory" . '->getPermissionManager()';
   $r->log_error("Building a manager using: $factory") if $debug;
   eval($factory) or $r->log_error("Evaluation failed: $@");

   return $managers{$name};
}

# This is the method that receives the login form data and decides if the 
# user is allowed to log in.
sub authen_cred
{
   my $this = shift;  # Package name (same as AuthName directive)
   my $r    = shift;  # Apache request object
   my @cred = @_;     # Credentials from login form
   my $debug = $r->dir_config("SiteControlDebug") || 0;
   my $checker = $r->dir_config("SiteControlMethod") || "Apache::SiteControl::Radius";
   my $factory = $r->dir_config("SiteControlUserFactory") || "Apache::SiteControl::UserFactory";
   my $user = undef;
   my $ok;

   # Load the user authentication module
   eval "require $checker" or $r->log_error("Could not load $checker: $@");
   eval "require $factory" or $r->log_error("Could not load $factory: $@");
   eval '$ok = ' . ${checker} . '::check_credentials($r, @cred)' or $r->log_error("authentication error code: $@");

   if($ok) {
      eval('$user = ' . "$factory" . '->makeUser($r, @cred)');
      if($@) {
         $r->log_error("Error reported during call to ${factory}->makeUser: $@");
      }
   }

   return $user->{sessionid} if defined($user);

   return undef;
}

# This sub is called for every request that is under the control of
# SiteControl. It is responsible for verifying that the user id (session
# key) is valid and that the user is ok.
# It returns a user name if all is well, and undef if not.
sub authen_ses_key
{
   my ($this, $r, $session_key) = @_;
   my $debug = $r->dir_config("SiteControlDebug") || 0;
   my $factory = $r->dir_config("SiteControlUserFactory") || "Apache::SiteControl::UserFactory";
   my $user = undef;

   eval "require $factory" or $r->log_error("Could not load $factory: $@");
   $r->log_error("Attempting auth using session key $session_key") if $debug;
   eval {
      eval('$user = ' . "$factory" . '->findUser($r, $session_key)');
      if($@) {
         $r->log_error("Error reported during call to ${factory}->findUser: $@");
      }
   };
   if($@) {
      $r->log_error("User tried access with invalid/nonexistent session: $@");
      return undef;
   }

   return $user->getUsername if defined($user);

   return undef;
}

1;

__END__

=head1 NAME

Apache::SiteControl - Perl web site authentication/authorization system

=head1 SYNOPSIS

See samples/site for complete example. Note, this module is intended for
mod_perl. See Apache2::SiteControl for mod_perl2.

=head1 DESCRIPTION

Apache::SiteControl is a set of perl object-oriented classes that
implement a fine-grained security control system for a web-based application.
The intent is to provide a clear, easy-to-integrate system that does not
require the policies to be written into your application components. It
attempts to separate the concerns of how to show and manipulate data from the
concerns of who is allowed to view and manipulate data and why.

For example, say your web application is written in HTML::Mason. Your
individual "screens" are composed of Mason modules, and you would like to keep
those as clean as possible, but decisions have to be made about what to allow
as the component is processed. SiteControl attempts to make that as easy as
possible.

=head2 DEVELOPER'S VIEWPOINT - EXAMPLE

In this document we use HTML::Mason to create examples of how to use the
control mechanisms, but any mod_perl based system should be supportable.

A good mason component tries to do most of the perl processing in a separate
block, so that simple substitutions can be made in HTML in the rest of
the page. This makes it much easier for web developers and perl developers to
co-exist on a project. 

The SiteControl system tries to make it possible to continue to follow this
model. You obtain a user object and permission manager from the SiteControl
system. These are intended to be opaque data types to the page designer,
and are defined elsewhere (see USERS). The actual web page component
should carry these objects around without implementing anything in the way of
policy.

For example, your mason component might look like this:

   <HTML>
      <HEAD> ... </HEAD>
   % if($manager->can($currentUser, "edit", $table)) {
         <FORM METHOD=POST ACTION="...">
            <P><INPUT TYPE=TEXT NAME="x" VALUE="<% $table->{x} %>">
            ...
         </FORM>
   % } else {
         <P>x is <% $table->{x} %>
   % }

   <%init>
   my $currentUser = Apache::SiteControl->getCurrentUser($r);
   my $manager = Apache::SiteControl->getPermissionManager($r);

   ... application specific stuff...
   i.e. 

   my $table = ...
   </%init>

Notice that the component does not bother looking at the user object, and there
is no policy code...just a request for permission:

   if($manager->can($currentUser, "do something to", $resource))

Of course the developer needs to know I<something> about the underlying system.
For example, the action string "do something to" is rather arbitrary. These can
be anything, and must be specified as rule actions. It is recommended that you
use some form of Perl constants for these instead of strings, but that is up to
you.

The resource is intended to be less opaque. This is likely the object that the
page developer wants to muck with, and so probably knows the internals of that
object a bit better. This is the crossover point from what SiteControl can
figure out on its own to information you have to supply. 

The default behavior is for the manager to deny any request.  In order for a
request to be approved, someone has to write a rule that joins together the
user, action, and resource and makes a decision about the permissibility of the
action.

If all you want is login and user tracking (but no permission manager), then it
is safe to ignore the permission manager altogether.

=head1 USERS

Users and Rules are the central components of the SiteControl system. The user
object must be Apache::SiteControl::User (or a subclass). See
Apache::SiteControl::User for a description of what it supports (session
storage, logout, etc.).  The glue to SiteControl is the UserFactory, which you
can define or accept the default of Apache::SiteControl::UserFactory
(recommended). 

Whenever a login attempt succeeds, the factory returns an object that
represents a valid, logged-in user. See Apache::SiteControl::UserFactory for
more information.

=head2 PERMISSION MANAGER

Each site will have a permission manager. There is usually no need for you
to subclass Apache::SiteControl::PermissionManager, but you do need to create one
and populate it with your access rules. You do this by creating a
factory class, which looks something like this:

   package samples::site::MyPermissionFactory;

   use Apache::SiteControl::PermissionManager;
   use Apache::SiteControl::GrantAllRule;
   use samples::site::EditControlRule;

   use base qw(Apache::SiteControl::ManagerFactory);

   our $manager;

   sub getPermissionManager
   {
      return $manager if defined($manager);

      $manager = new Apache::SiteControl::PermissionManager;
      $manager->addRule(new Apache::SiteControl::GrantAllRule);
      $manager->addRule(new samples::site::EditControlRule);

      return $manager;
   }

   1;

The primary goal of your factory is to produce an instance of a permission 
manager that knows the rules for permitting access to your site. This is 
an easy process that involves calling the constructor (via new) and then
calling addRule one or more times.

=head2 RULES

The PermissionManager is the object that the site developers ask about
what is allowed and what is not. As you saw in the previous section, you 
create a manager, and add some rules.

Each rule is a custom-written class that implements some aspect of your
site's access logic. Rules can choose to grant or deny a request. The following
is a pretty complex example that demonstrates the features of a rule. 

Most rules with either specifically grant permission, or deny it. Most will not
deal with both possibilities. In this example we are assuming that the user is
implemented as an object that has attributes which can be retrieved with a
getAttribute method (of course, you would have to have implemented that as
well). The basic action that this rule handles is called "beat up", so the site
makes calls like: 
 
   if($referee->can($userA, "beat up", $userB)) { ... }

In terms of English, we would describe the rule "If A is taller than B, then
we say that A can beat up B. If A is less skilled than B, then we say that
A cannot beat up B".  The rule looks like this:

   package samples::FightRules;

   use strict;
   use warnings;
   use Carp;
   use Apache::SiteControl::Rule;

   use base qw(Apache::SiteControl::Rule);

   sub grants($$$$)
   {
      my $this = shift;
      my $user = shift;
      my $action = shift;
      my $resource = shift;

      if($action eq "beat up" && $resource->isa("Apache::SiteControl::User")) {
         my ($h1, $h2);
         $h1 = $user->getAttribute("height");
         $h2 = $resource->getAttribute("height");
         return 1 if(defined($h1) && defined($h2) && $h1 > $h2);
      }

      return 0;
   }

   sub denies($$$$)
   {
      my $this = shift;
      my $user = shift;
      my $action = shift;
      my $resource = shift;

      if($action eq "beat up" && $resource->isa("Apache::SiteControl::User")) {
         my ($s1, $s2);
         $s1 = $user->getAttribute("skill");
         $s2 = $resource->getAttribute("skill");
         return 1 if(defined($s1) && defined($s2) && $s1 < $s2);
      }

      return 0;
   }

   1;

The PermissionManager will only give permission if I<at least> one rule grants
permission, I<and> no rule denies it. 

I think it is clearer to separate rules like the previous one into separate
rule classes altogether. A HeightMakesMightRule and a DefenseSkillRule.
Splitting into two rules makes things clearer, and there is no limit to the
number of rules that the PermissionManager can check.

It is important that your rules never grant or deny a request they do not
understand, so it is a good idea to use type checking to prevent strangeness.
B<Assertions should not be used> if you expect different rules to accept
different resource types or user types, since each rule is used on every access
request.

=head1 EXPORT

None by default.

=head1 SEE ALSO

Apache::SiteControl::UserFactory, Apache::SiteControl::ManagerFactory,
Apache::SiteControl::PermissionManager, Apache::SiteControl::Rule

=head1 AUTHOR

This module was written by Tony Kay, E<lt>tkay@uoregon.eduE<gt>.

=head1 COPYRIGHT AND LICENSE

This modules is covered by the GNU public license.
=cut

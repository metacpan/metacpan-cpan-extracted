package Apache::SiteControl::PermissionManager;

use 5.008;
use strict;
use warnings;
use Carp;

our $VERSION = "1.0";

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $this  = { rules => [] };
   bless ($this, $class);
   return $this;
}

sub addRule($$)
{
   my $this = shift;
   my $rule = shift;

   push @{$this->{rules}}, $rule;

   return 1;
}

sub can($$$$)
{
   my $this = shift;
   my $user = shift;
   my $action = shift;
   my $resource = shift;
   my $rule;
   my ($granted, $denied) = (0,0);

   for $rule (@{$this->{rules}})
   {
      $granted = 1 if($rule->grants($user, $action, $resource));
      $denied = 1 if($rule->denies($user, $action, $resource));
   }

   return ($granted && !$denied);
}

1;

__END__

=head1 NAME

Apache::SiteControl::PermissionManager - Rule-based permission management

=head1 SYNOPSIS

  use Apache::SiteControl::PermissionManager;

  $manager = new Apache::SiteControl::PermissionManager();
  $rule1 = new SomeSubclassOfSiteControl();
  $manager->addRule($rule1);
  ...

  $user = new SomeUserTypeYouDefineThatMakesSenseToRules;

  if($manager->can($user, $action, $resource)) {
     # OK to do action
  }

  # For example

  if($manager->can($user, "read", "/etc/shadow")) {
     open DATA, "</etc/shadow";
     ...
  }

=head1 DESCRIPTION

This module implements a user capabilities API. The basic idea is that you have
a set of users and a set of things that can be done in a system. In the code of
the system itself, you want to surround sensitive operations with code that
determines if the current user is allowed to do that operation.

This module attempts to make such a system possible, and easily extensible.
The module requires that you write implementations of rules for you system
that are subclasses of Apache::SiteControl::Rule. The rules can be written to 
use any data types, which are abstractly known as "users", "actions", and
"resources." 

A user is some object that your applications uses to identify the person
operating the program. The expectation is that at some point the application 
authenticated the user and obtained their identity, and the rest of the 
application is merely applying a ruleset to determine what that user is
allowed to do. In the context of the SiteControl system, this user is a 
Apache::SiteControl::User or subclass thereof.

An action can be any data type (i.e. simply a string). Again, it is really up
to the code of the rules (which are primarily written by you) to determine what
is valid.

The overall usage of this package is as follows:

=over 8

=item B<1.> Decide how you want to represent a user. (i.e. Apache::SiteControl::User)

=item B<2.> Decide the critical sections of your code that need to be
protected, and decide what to do if the user doesn't pass muster. For example
if a screen should just hide fields, then the application code needs to reflect
that.

=item B<3.> Create a permission manager instance for your application.
Typically use a singleton pattern (there need be only one manager). In the
SiteControl system, this is done by a ManagerFactory that you write.

=item B<4.> Surround sensitive sections of code with something like:

   if($manager->can($user, "view salary", $payrollRecord))
   {
      # show salary fields
   } else
      # hide salary fields
   }

=item B<5.> Create rules that spell out the behavior you want and add them to
your application's permission manager. The basic idea is that a rule can grant
permission, or deny it. If it neither grants or denies, then the manager will
take the safe route and say that the action cannot be taken. Part of the code
for the rule for protecting salaries might look like:

   package SalaryViewRule;

   use Apache::SiteControl::Rule;
   use Apache::SiteControl::User;

   use base qw(Apache::SiteControl::Rule);

   sub grants
   {
      $this = shift;
      $user = shift;
      $action = shift;
      $resource = shift;

      # Do not grant on requests we don't understand.
      return 0 if(!$user->isa("Apache::SiteControl::User") ||
                  !$this->isa("Apache::SiteControl::Rule"));

      if($action eq "view salary" && $resource->isa("Payroll::Record")) {
         if($user->getUsername() eq $resource->getEmployeeName()) {
            return "user can view their own salary";
         }
      }
      return 0;
   }

Then in your subclass of ManagerFactory:

   use SalaryViewRule;

   ...

   $viewRule = new SalaryViewRule;
   $manager->addRule($viewRule);

=back

=head1 METHODS

=over 8

=item B<can>(I<user>, I<action verb>, I<resource>)

This is the primary method of the PermissionManager. It asks if the specified
user can do the specified action on the specified resource. For example,

   $manager->can($user, "eat", "cake");

would return true if the user is allowed to eat cake. Note that this gives you 
quite a bit of flexibility, but at the expense of strong type safety. It is
suggested that all of your rules do type checking to insure that a rule is 
properly applied. 

=back

=head1 SEE ALSO

Apache::SiteControl::Rule, Apache::SiteControl::ManagerFactory,
Apache::SiteControl::UserFactory, Apache::SiteControl

=head1 AUTHOR

This module was written by Tony Kay, E<lt>tkay@uoregon.eduE<gt>.

=head1 COPYRIGHT AND LICENSE

=cut

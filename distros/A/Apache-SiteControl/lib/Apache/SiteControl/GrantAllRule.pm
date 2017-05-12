package Apache::SiteControl::GrantAllRule;

use 5.008;
use strict;
use warnings;
use Carp;
use Carp::Assert;
use Apache::SiteControl::Rule;

use base qw(Apache::SiteControl::Rule);

our $VERSION = "1.0";

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $this  = { };
   bless ($this, $class);
   return $this;
}

sub grants($$$$)
{
   my $this = shift;
   my $user = shift;
   my $action = shift;
   my $resource = shift;

   return "Default is to allow";
}

sub denies($$$$)
{
   my $this = shift;
   my $user = shift;
   my $action = shift;
   my $resource = shift;

   return 0;
}

1;

__END__

=head1 NAME

Apache::SiteControl::GrantAllRule - A rule that grants permission to do everything.

=head1 SYNOPSIS

In your instance of a ManagerFactory:

=over 4

   use Apache::SiteControl::GrantAllRule;
   ...

   sub getPermissionManager
   {
      ...

      $manager->addRule(new Apache::SiteControl::GrantAllRule);

      ...

      return $manager;
   }

=back

=head1 DESCRIPTION

Apache::SiteControl::GrantAllRule is a pre-built rule that grants access for
all permission requests. This rule can be used to help implement a system that
has a default policy of allowing access, and to which you add rules that deny
access for specific cases.

Note that the loose type checking of Perl makes this inherently dangerous, 
since a typo is likely to fail to deny access. It is recommended that you
take the opposite approach with your rules, since a typo will err on the 
side of denying access. The former is a security hole, the latter is a bug
that people will complain about (so you can fix it).

=head1 SEE ALSO

Apache::SiteControl::ManagerFactory, Apache::SiteControl::PermissionManager,
Apache::SiteControl::Rule

=head1 AUTHOR

This module was written by Tony Kay, E<lt>tkay@uoregon.eduE<gt>.

=head1 COPYRIGHT AND LICENSE

=cut

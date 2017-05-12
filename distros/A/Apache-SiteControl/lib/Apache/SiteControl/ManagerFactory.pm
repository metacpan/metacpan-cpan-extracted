package Apache::SiteControl::ManagerFactory;

use 5.008;
use strict;
use warnings;
use Carp;
use Carp::Assert;

our $VERSION = "1.0";

sub getPermissionManager
{
   croak "Attempt to call abstract method getPermissionManager";
}

1;

__END__

=head1 NAME

Apache::SiteControl::ManagerFactory - An abstract base class to use as a
pattern for custom PermissionManager production.

=head1 DESCRIPTION

This package is a simple abstract base class. Use it as the base for creating
your instances of permission managers. For example,

package MyManagerFactory;

use strict;
use Apache::SiteControl::ManagerFactory;

use base qw(Apache::SiteControl::ManagerFactory);

our $manager;

sub getPermissionManager
{
   return $manager if(defined($manager) && $manager->isa(Apache::SiteControl::ManagerFactory));

   $manager = new Apache::SiteControl::PermissionManager;

   $manager->addRule(new XYZRule);
   $manager->addRule(new SomeOtherRule);

   return $manager;
}

1;

=head1 SEE ALSO

Apache::SiteControl::PermissionManager, Apache::SiteControl::Rule

=head1 AUTHOR

This module was written by Tony Kay, E<lt>tkay@uoregon.eduE<gt>.

=head1 COPYRIGHT AND LICENSE

=cut

package MyPermissionFactory;

use Apache2::SiteControl::PermissionManager;
use Apache2::SiteControl::GrantAllRule;
use EditControlRule;

our $manager;

sub getPermissionManager
{
   return $manager if defined($manager);

   $manager = new Apache2::SiteControl::PermissionManager;
   $manager->addRule(new Apache2::SiteControl::GrantAllRule);
   $manager->addRule(new EditControlRule);

   return $manager;
}

1;

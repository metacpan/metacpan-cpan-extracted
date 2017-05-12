package MyPermissionFactory;

use Apache::SiteControl::PermissionManager;
use Apache::SiteControl::GrantAllRule;
use EditControlRule;

our $manager;

sub getPermissionManager
{
   return $manager if defined($manager);

   $manager = new Apache::SiteControl::PermissionManager;
   $manager->addRule(new Apache::SiteControl::GrantAllRule);
   $manager->addRule(new EditControlRule);

   return $manager;
}

1;

package EditControlRule;

use Apache::SiteControl::Rule;

@ISA = qw(Apache::SiteControl::Rule);

# This rule is going to be used in a system that automatically grants
# permission for everything (via the GrantAllRule). So this rule will
# only worry about what to deny, and the grants method can return whatever.
# Note that writing a deny-based system is inherently more dangerous and 
# buggy because of the lack of type-safety. Typos in the HTML components can
# cause a rule to fail to deny an invalid request, which is typically less
# desirable than failing to grant a request. The former is a security hole that
# might get missed; the latter is a bug that gets quickly reported.
sub grants($$$$)
{
   return 0;
}

sub denies($$$$)
{
   my ($this, $user, $action, $resource) = @_;

   return 1 if($action eq "edit" && $user->getUsername ne "admin");

   return 0;
}

1;

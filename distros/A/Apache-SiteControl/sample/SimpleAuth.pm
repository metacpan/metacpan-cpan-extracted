package SimpleAuth;

use 5.008;
use strict;
use warnings;

sub check_credentials
{
   my $r    = shift;  # Apache request object
   my $username = shift;
   my $password = shift;

   return 1 if($username eq 'admin' && $password eq 'test');
   return 1 if($username eq 'user' && $password eq 'test');

   return 0;
}

1;


package My::ErrorHandler;

use strict;
use warnings 'all';
use base 'Apache2::ASP::ErrorHandler';
use vars __PACKAGE__->VARS;


#==============================================================================
sub run
{
  my ($s, $context) = @_;
  
  $Response->Write( $Stash->{error}->{stacktrace} );
  
  eval {
    $s->SUPER::run( $context );
  };
}# end run()

1;# return true:


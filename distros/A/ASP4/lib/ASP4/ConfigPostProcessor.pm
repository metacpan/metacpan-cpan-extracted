
package
ASP4::ConfigPostProcessor;

use strict;
use warnings 'all';


sub new
{
  my ($class, %args) = @_;
  
  return bless \%args, $class;
}# end new()


sub post_process($$);

1;# return true:


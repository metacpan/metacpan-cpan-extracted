
package
ASP4::Test::Fixtures;

use strict;
use warnings 'all';
use base 'Data::Properties::YAML';

sub as_hash
{
  wantarray ? %{ $_[0]->{data} } : $_[0]->{data};
}# end as_hash()

1;# return true:


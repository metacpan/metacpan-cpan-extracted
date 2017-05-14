use strict;
package Catalyst::Helper::Model::MetaCPAN;

sub mk_compclass {
  my ($self, $helper) = @_;
  my $file = $helper->{file};
  $helper->render_file('compclass', $file);
}

1;

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;

use parent 'Catalyst::Model::MetaCPAN';

1;

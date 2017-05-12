
package App::FQStat::PAR;
# App::FQStat is (c) 2007-2009 Steffen Mueller
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;

sub _par_required_modules {
  die; # never call this, this is just for the dep scanner
  require POSIX;
  require Tie::Hash;
}

1;



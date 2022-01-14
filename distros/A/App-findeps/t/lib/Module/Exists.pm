package Module::Exists;

use strict;
use warnings;

use Exporter 'import';
our $VERSION   = 0.00;
our @EXPORT_OK = qw( $VERSION dummy is_dummy );

use Module::CoreList;    # MUST be installed in 5.8 or later

sub dummy    {@_}
sub is_dummy { defined $_[0] }

1;

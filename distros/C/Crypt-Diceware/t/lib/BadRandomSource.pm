use 5.008001;
use strict;
use warnings;

package BadRandomSource;

use Data::Entropy::Source;

my $data = pack( "C*", (0) x 20 );
open my $fh, "<", \$data;

sub source { return Data::Entropy::Source->new( $fh, "getc" ) }

1;

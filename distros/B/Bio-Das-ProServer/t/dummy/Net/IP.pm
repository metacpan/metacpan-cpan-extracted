#########
# dummy
#
package Net::IP;
use strict;
use warnings;
use base qw(Exporter);

our ($IP_A_IN_B_OVERLAP, $IP_IDENTICAL);
our @EXPORT = qw($IP_A_IN_B_OVERLAP $IP_IDENTICAL Error);

sub Error {
}

1;

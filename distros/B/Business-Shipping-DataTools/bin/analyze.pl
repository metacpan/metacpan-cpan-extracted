use strict;
use warnings;

use Storable;
use Data::Dumper;

=head1 DESCRIPTION

analyze.pl - Analyze a Business::Shipping::DataFiles data file

For debugging purposes.

=cut

die "Usage: $0 <filename.dat>" unless @ARGV;

my $filepath = $ARGV[ 0 ];
my $hashref = Storable::retrieve( $filepath ) || die "Could not Storable::retrieve from file '$filepath': $@";

print Dumper( $hashref );


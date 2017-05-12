#!/usr/bin/perl -w

# Author          : Johan Vromans
# Created On      : Fri Oct 21 09:18:23 2016
# Last Modified By: Johan Vromans
# Last Modified On: Mon Oct 24 16:05:33 2016
# Update Count    : 190
# Status          : Unknown, Use with caution!

################ Common stuff ################

=head1 NAME

Comics - comics aggregator in the style of Gotblah

=head1 SYNOPSIS

  perl Comics.pm [options] [plugin ...]

If the associated C<collect> tool has been installed properly:

  collect [options] [plugin ...]

See L<Comics> for the documentation.

=cut

use 5.012;
use strict;
use warnings;
use FindBin;

BEGIN {
    # Add private library if it exists.
    if ( -d "$FindBin::Bin/../lib" ) {
	unshift( @INC, "$FindBin::Bin/../lib" );
    }
}

use Comics;

main();

1;

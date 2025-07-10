#!/usr/bin/env perl

use strict;
use warnings;

use Data::OFN::Common::Quantity;

my $obj = Data::OFN::Common::Quantity->new(
        'value' => 1,
        'unit' => 'KGM',
);

# Print out.
print 'Value: '.$obj->value."\n";
print 'Unit: '.$obj->unit."\n";

# Output:
# Value: 1
# Unit: KGM
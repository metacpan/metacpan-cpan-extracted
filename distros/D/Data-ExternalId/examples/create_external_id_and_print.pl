#!/usr/bin/env perl

use strict;
use warnings;

use Data::ExternalId;

my $obj = Data::ExternalId->new(
        'key' => 'Wikidata',
        'value' => 'Q27954834',
);

# Print out.
print "External id key: ".$obj->key."\n";
print "External id value: ".$obj->value."\n";

# Output:
# External id key: Wikidata
# External id value: Q27954834
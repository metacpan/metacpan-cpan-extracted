#!/usr/bin/env perl

use strict;
use warnings;

use Data::CEFACT::Unit;

my $obj = Data::CEFACT::Unit->new(
        'common_code' => 'KGM',
        'conversion_factor' => 'kg',
        'description' => 'A unit of mass equal to one thousand grams.',
        'level_category' => 1,
        'name' => 'kilogram',
        'symbol' => 'kg',
);

# Print out.
print 'Name: '.$obj->name."\n";
print 'Description: '.$obj->description."\n";
print 'Common code: '.$obj->common_code."\n";
print 'Status: '.(! defined $obj->status ? 'valid' : $obj->status)."\n";
print 'Symbol: '.$obj->symbol."\n";
print 'Level/Category: '.$obj->level_category."\n";
print 'Conversion factor: '.$obj->conversion_factor."\n";

# Output:
# Name: kilogram
# Description: A unit of mass equal to one thousand grams.
# Common code: KGM
# Status: valid
# Symbol: kg
# Level/Category: 1
# Conversion factor: kg
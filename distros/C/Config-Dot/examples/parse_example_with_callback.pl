#!/usr/bin/env perl

use strict;
use warnings;

use Config::Dot;
use Data::Printer;

# Object.
my $struct_hr = Config::Dot->new(
        'callback' => sub {
               my ($key_ar, $value) = @_;
               if ($key_ar->[0] eq 'key3' && $key_ar->[1] eq 'subkey1'
                       && $value eq 'value3') {

                       return 'FOOBAR';
               }
               return $value;
        },
)->parse(<<'END');
key1=value1
key2=value2
key3.subkey1=value3
END

# Dump.
p $struct_hr;

# Output:
# {
#     key1   "value1",
#     key2   "value2",
#     key3   {
#         subkey1   "FOOBAR"
#     }
# }
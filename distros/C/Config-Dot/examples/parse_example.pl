#!/usr/bin/env perl

use strict;
use warnings;

use Config::Dot;
use Data::Printer;

# Object.
my $struct_hr = Config::Dot->new->parse(<<'END');
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
#         subkey1   "value3"
#     }
# }
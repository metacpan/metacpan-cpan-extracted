#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Dot::Array;
use Dumpvalue;

# Object.
my $struct_hr = Config::Dot::Array->new->parse(<<'END');
key1=value1
key2=value2
key2=value3
key3.subkey1=value4
key3.subkey1=value5
END

# Dump
my $dump = Dumpvalue->new;
$dump->dumpValues($struct_hr);

# Output:
# 0  HASH(0x9970430)
#    'key1' => 'value1'
#    'key2' => ARRAY(0x9970660)
#       0  'value2'
#       1  'value3'
#    'key3' => HASH(0x9970240)
#       'subkey1' => ARRAY(0xa053658)
#          0  'value4'
#          1  'value5'
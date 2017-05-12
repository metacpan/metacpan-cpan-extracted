#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Dot;
use Dumpvalue;

# Object.
my $struct_hr = Config::Dot->new->parse(<<'END');
key1=value1
key2=value2
key3.subkey1=value3
END

# Dump
my $dump = Dumpvalue->new;
$dump->dumpValues($struct_hr);

# Output:
# 0  HASH(0x84b98a0)
#    'key1' => 'value1',
#    'key2' => 'value2',
#    'key3' => HASH(0x8da3ab0)
#       'subkey1' => 'value3',
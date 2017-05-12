#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use Config::Dot::Array;
use Dumpvalue;

# Object.
my $struct_hr = Config::Dot::Array->new(
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
key3.subkey1=value4
END

# Dump
my $dump = Dumpvalue->new;
$dump->dumpValues($struct_hr);

# Output:
# 0  HASH(0x87d05e8)
#    'key1' => 'value1'
#    'key2' => 'value2'
#    'key3' => HASH(0x87e3840)
#       'subkey1' => ARRAY(0x87e6f68)
#          0  'FOOBAR'
#          1  'value4'
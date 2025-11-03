
use strict;
use warnings;
use Data::HexConverter;

my $hexToBinImplementation   = Data::HexConverter::hex_to_binary_impl();
my $binToHexImplementation   = Data::HexConverter::binary_to_hex_impl();

print "Hex to Binary Implementation:\n$hexToBinImplementation\n";
print "Binary to Hex Implementation:\n$binToHexImplementation\n";




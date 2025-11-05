use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Data::HexConverter');
}

# convert hex to binary and back
# size is 1M of random hex string
{
	 my @shuffled_hex_characters = qw( A 2 0 3 1 D 4 E 6 F B 7 8 9 A C 5);
	 my $hex_string = join('', map { $shuffled_hex_characters[rand @shuffled_hex_characters] } 1..1048576);
	 #print "Hex string: $hex_string\n";
    my $bin = Data::HexConverter::hex_to_binary(\$hex_string);
	 my $reconsitituted_hex = Data::HexConverter::binary_to_hex(\$bin);
	 is($reconsitituted_hex, $hex_string, 'Hex to binary and back to hex works correctly');
}


done_testing;


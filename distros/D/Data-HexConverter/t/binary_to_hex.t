use strict;
use warnings;
use Test::More;

#BEGIN {
#use_ok('Data::HexConverter');
#}
use Data::HexConverter;

print 2, "Testing Data::HexConverter::binary_to_hex...\n";

# Test simple conversion of ASCII text to uppercase hex.
{
    my $bin = "Hello";
    my $hex = Data::HexConverter::binary_to_hex(\$bin);
    is($hex, "48656C6C6F", 'binary_to_hex converts "Hello"');
}


# Mixed letters should remain uppercase in output.
{
    my $bin = "JKL";
    my $hex = Data::HexConverter::binary_to_hex(\$bin);
    is($hex, "4A4B4C", 'binary_to_hex handles uppercase letters');
}

# Arbitrary byte values including 0x00 and high bits.
{
    my $bin = pack("C*", 0x00, 0xFF, 0x7F, 0x80);
    my $hex = Data::HexConverter::binary_to_hex(\$bin);
    is($hex, "00FF7F80", 'binary_to_hex handles non-ASCII bytes');
}

# Empty input should return an empty string
{
	#my $bin = pack("C*", 0x61);
	#my $hex = Data::HexConverter::binary_to_hex(\$bin);
	#is($hex, "61", 'binary_to_hex returns empty string on empty input');
	my $himpl   = Data::HexConverter::hex_to_binary_impl();
	my $bimpl   = Data::HexConverter::binary_to_hex_impl();

	print "Using binary_to_hex implementation: $bimpl\n";
	print "Using hex_to_binary implementation: $himpl\n";

	my $bin = "";
	my $hex = Data::HexConverter::binary_to_hex(\$bin);
	is($hex, "", 'binary_to_hex returns empty string on empty input');
}

=head1 test
#
# Argument must be a reference
{
    my $error;
    eval { Data::HexConverter::binary_to_hex('abc') };
    $error = $@;
    like($error, qr/Argument must be a reference/, 'non-reference argument croaks');
}

=cut

done_testing;


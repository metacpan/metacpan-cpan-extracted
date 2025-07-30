use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('Data::HexConverter');
}

# Test that simple conversions work correctly.
{
    my $hex = "48656c6c6f";       # "Hello" in hex
    my $bin = Data::HexConverter::hex_to_binary(\$hex);
    is($bin, "Hello", 'simple conversion of "48656c6c6f"');
}

{
    my $hex = "4a4B4c";            # mixed case: "JKL"
    my $bin = Data::HexConverter::hex_to_binary(\$hex);
    is($bin, "JKL", 'conversion handles mixed case hex');
}

# Empty input should return an empty string
{
    my $hex = "";
    my $bin = Data::HexConverter::hex_to_binary(\$hex);
    is($bin, "", 'empty input returns empty string');
}

# Odd length hex strings should croak
{
    my $bad = "123";
    my $error;
    eval { Data::HexConverter::hex_to_binary(\$bad) };
    $error = $@;
    like($error, qr/Hex string length must be even/, 'odd length croaks with correct message');
}

# Invalid characters should croak
{
    my $bad = "00ZZ";
    my $error;
    eval { Data::HexConverter::hex_to_binary(\$bad) };
    $error = $@;
    like($error, qr/Invalid hex digit/, 'invalid characters croak with correct message');
}

done_testing;


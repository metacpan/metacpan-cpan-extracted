#!/usr/bin/env perl
# Numeric encoding under a non-C LC_NUMERIC locale (where the decimal
# separator is comma). Catches any path that uses locale-aware printf /
# strtod for floats or decimals -- those would emit "1,5" in the wire
# bytes, which ClickHouse can't parse.
#
# Skip if the host doesn't have de_DE.UTF-8 (or fr_FR or any comma locale)
# available; the test only fails when an actual comma-decimal locale is
# successfully set.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use POSIX qw(setlocale LC_NUMERIC);
use ClickHouse::Encoder;

my @candidates = qw(de_DE.UTF-8 de_DE.utf8 fr_FR.UTF-8 fr_FR.utf8 ru_RU.UTF-8);
my $picked;
for my $loc (@candidates) {
    if (defined setlocale(LC_NUMERIC, $loc)) { $picked = $loc; last }
}
plan skip_all => "no comma-decimal locale installed (tried @candidates)"
    unless $picked;

# Confirm the locale actually flips the decimal separator.
my $sample = sprintf '%.1f', 1.5;
plan skip_all => "locale '$picked' does not affect decimal separator"
    unless $sample =~ /,/;
diag "locale set: $picked (sprintf 1.5 = '$sample')";

# Float64: encode 1.5 and decode back as a double; bytes must equal the
# C-locale representation regardless of the active locale.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Float64']]);
    my $bin = $enc->encode([[1.5]]);
    my $tail = substr($bin, length($bin) - 8, 8);
    my $val = unpack 'd<', $tail;
    is($val, 1.5, 'Float64: 1.5 round-trips through bytes under comma-locale');
}

# Float32 likewise.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Float32']]);
    my $bin = $enc->encode([[1.5]]);
    my $val = unpack 'f<', substr($bin, length($bin) - 4, 4);
    is($val, 1.5, 'Float32: 1.5 round-trips under comma-locale');
}

# Decimal32(2) from a string-typed value with a dot decimal.  The
# encoder's exact-decimal string path must accept "1.5" verbatim, not
# need a comma even if locale-aware strtod is in play.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal32(2)']]);
    my $bin = $enc->encode([['1.5']]);
    my $v = unpack 'l<', substr($bin, length($bin) - 4, 4);
    is($v, 150, 'Decimal32(2): "1.5" parses as 1.50 (=150) under comma-locale');
}

# Decimal32(2) from a numeric scalar.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal32(2)']]);
    my $bin = $enc->encode([[1.5]]);
    my $v = unpack 'l<', substr($bin, length($bin) - 4, 4);
    is($v, 150, 'Decimal32(2): numeric 1.5 also encodes as 150');
}

done_testing();

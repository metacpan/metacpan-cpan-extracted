use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 2;
use CLDR::Number;

my $cldr = CLDR::Number->new;

# Tests adapted from ICU4C:
# source/test/intltest/numfmtst.cpp

# NumberFormatTest::TestPerMill
my $perf = $cldr->percent_formatter(permil => 1);
$perf->pattern('###.###%');
is $perf->format(0.4857), '485.7‰', '0.4857 x ###.###‰';
$perf->permil_sign('m');
is $perf->format(0.4857), '485.7m', '0.4857 x ###.###m';

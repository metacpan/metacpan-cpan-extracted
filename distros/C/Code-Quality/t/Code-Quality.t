#!/usr/bin/perl
use strict;
use warnings;
use lib '.';

use t::lib;
use Test::More tests => 9;
BEGIN { use_ok('Code::Quality', qw/:all/) };

local $Code::Quality::DEBUG = \&Test::More::note;

my $reference = $t::lib::reference;
my $long_code = $t::lib::long_code;
my $bla = join "\n", 'void bla(void) {', ((';') x 100), '}';

sub is_star_rating {
	my ($code, $expected, $message) = @_;
	my $warnings = analyse_code(code => $code, reference => $reference, language => 'TEXT');
	my $rating = star_rating_of_warnings($warnings) // 0;
	is $rating, $expected, $message;
}

is_star_rating $reference, 3, 'reference code gets 3 stars';
is_star_rating $long_code, 2, 'long code gets 2 stars';
is_star_rating "$long_code$bla", 1, 'very long code gets 1 star';

sub artificial_lines_test {
	my ($expected_stars, $reference_length, $code_length) = @_;
	my $code = "bla\n" x $code_length;
	my $reference = "bla\n" x $reference_length;
	my $stars = star_rating_of_warnings test_lines code => $code, reference => $reference, language => 'bla';
	is $stars, $expected_stars, "artificial_lines: $code_length loc (vs $reference_length) "
}

artificial_lines_test 3, 10, 10;
artificial_lines_test 3, 10, 20;
artificial_lines_test 2, 5, 12;
artificial_lines_test 3, 50, 70;
artificial_lines_test 2, 50, 73;

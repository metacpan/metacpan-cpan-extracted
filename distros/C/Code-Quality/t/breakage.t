#!/usr/bin/perl
use strict;
use warnings;
use lib '.';

use t::lib;
use Code::Quality qw/:all/;
use Test::More;

BEGIN {
	plan skip_all => 'clang-tidy not found' unless Code::Quality::_clang_tidy_exists;
	plan tests => 7;
}

our ($reference, $language);

sub is_star_rating {
	my ($code, $expected, $message) = @_;
	my $warnings = analyse_code(code => $code, reference => $reference, language => $language);
	my $rating = star_rating_of_warnings($warnings) // 0;
	is $rating, $expected, $message;
}

$language = 'TEXT';
is_star_rating $t::lib::long_code, 0, 'no reference and bad language';

$reference = '';
is_star_rating $t::lib::long_code, 0, 'empty reference';

$reference = 'int main(void) { return 0; }';
is_star_rating '', 3, 'empty code and bad language';

$language = 'C';
is_star_rating 'bla', 1, 'code does not compile';

undef $reference;
is_star_rating 'void main(void) {}', 1, 'void main, no reference';
is_star_rating 'int main(void) { return 1; }', 3, '/bin/false, no reference';

{
	local $ENV{PATH} = '';
	local $SIG{__WARN__} = sub {}; # ignore warning
	is_star_rating 'text here', 0, 'intentionally fail to run clang-tidy';
}

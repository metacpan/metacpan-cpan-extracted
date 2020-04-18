#!perl -T
use 5.8.0;
use strict;
use warnings;

use utf8;

our $VERSION='0.06';

binmode STDERR, ':encoding(UTF-8)';
binmode STDOUT, ':encoding(UTF-8)';
binmode STDIN,  ':encoding(UTF-8)';
# to avoid wide character in TAP output
# do this before loading Test* modules
use open ':std', ':encoding(utf8)';

use Test::More;

use Data::Random::Structure::UTF8;

use Scalar::Util qw/looks_like_number/;

# we are dealing with a random generator
# so give it a change to produce some unicode
# eventually after so many trials, it usually does after 1-10 trials
my $MAXTRIALS=100;

############################
#### nothing to change below
my $num_tests = 0;

my ($perl_var, $found, $found1, $found2, $trials, $rc, $alength, $randomiser);

# just a scalar unicode
$perl_var = 'αβγ';
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 0, "check_content_recursively() : numbers:  no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings'=>1,
}) == 1, "check_content_recursively() : strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>1,
	'strings-plain'=>0,
}) == 1, "check_content_recursively() : unicode strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>0,
	'strings-plain'=>1,
}) == 0, "check_content_recursively() : non-unicode strings: no."); $num_tests++;

#####
# just a scalar non-unicode
$perl_var = 'abc';
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 0, "check_content_recursively() : numbers:  no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings'=>1,
}) == 1, "check_content_recursively() : strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>1,
	'strings-plain'=>0,
}) == 0, "check_content_recursively() : unicode strings: no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>0,
	'strings-plain'=>1,
}) == 1, "check_content_recursively() : non-unicode strings: yes."); $num_tests++;

#####
# just a scalar mixed unicode and non-unicode
$perl_var = 'abcαβγ xyz χυζ aaa';
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 0, "check_content_recursively() : numbers:  no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings'=>1,
}) == 1, "check_content_recursively() : strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>1,
	'strings-plain'=>0,
}) == 1, "check_content_recursively() : unicode strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>0,
	'strings-plain'=>1,
}) == 0, "check_content_recursively() : non-unicode strings: no."); $num_tests++;

#####
# just a scalar number
$perl_var = 123;
ok(looks_like_number($perl_var), "looks like number: yes"); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 1, "check_content_recursively() : numbers:  yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings'=>1,
}) == 0, "check_content_recursively() : strings: no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>1,
	'strings-plain'=>0,
}) == 0, "check_content_recursively() : unicode strings: no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>0,
	'strings-plain'=>1,
}) == 0, "check_content_recursively() : non-unicode strings: no."); $num_tests++;

#####
# just a scalar number in a string
$perl_var = '123';
ok(looks_like_number($perl_var), "looks like number: yes"); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 1, "check_content_recursively() : numbers:  yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings'=>1,
}) == 0, "check_content_recursively() : strings: no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>1,
	'strings-plain'=>0,
}) == 0, "check_content_recursively() : unicode strings: no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>0,
	'strings-plain'=>1,
}) == 0, "check_content_recursively() : non-unicode strings: no."); $num_tests++;

#####
# just a scalar number in a string mixed with unicode and non-unicode
$perl_var = 'abcαβγ xyz χυζ aaa 123';
ok(!looks_like_number($perl_var), "looks like number: no"); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 0, "check_content_recursively() : numbers:  no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings'=>1,
}) == 1, "check_content_recursively() : strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>1,
	'strings-plain'=>0,
}) == 1, "check_content_recursively() : unicode strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>0,
	'strings-plain'=>1,
}) == 0, "check_content_recursively() : non-unicode strings: no."); $num_tests++;

#####
# complex data structures
$perl_var = {
	'χυζ' => 'abcαβγ xyz χυζ aaa 123',
	'abc' => {
		'123' => 'βγ xyz χυζ aa',
		'786' => ['α', 'β', 'c'],
	},
	'000' => [1,2,3],
};
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 1, "check_content_recursively() : numbers:  yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings'=>1,
}) == 1, "check_content_recursively() : strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>1,
	'strings-plain'=>0,
}) == 1, "check_content_recursively() : unicode strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>0,
	'strings-plain'=>1,
}) == 1, "check_content_recursively() : non-unicode strings: yes."); $num_tests++;

# check for each type and set the others to zero,
# it means don't bother checking (and not report if it doesn't exist)
$perl_var = {
	'strings-unicode' => 'ναι έχω και από αυτό',
	'strings-plain' => 'sure I have some',
	'numbers' => [1,2,3,123],
};
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
}) == 1, "check_content_recursively() : numbers:  yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'strings'=>1,
}) == 1, "check_content_recursively() : strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'strings-unicode'=>1,
}) == 1, "check_content_recursively() : unicode strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'strings-plain'=>1,
}) == 1, "check_content_recursively() : non-unicode strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0, # this means don't look, and not doesn't exist
	'strings-plain'=>1,
}) == 1, "check_content_recursively() : numbers:  yes."); $num_tests++;

# check for each type and set the others to zero,
# it means don't bother checking (and not report if it doesn't exist)
$perl_var = {
	# even keys are checked, so use a number for a key too!
	'123' => [1,2,3,123],
};
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
}) == 1, "check_content_recursively() : numbers:  yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 1, "check_content_recursively() : strings: no."); $num_tests++;

# check some edge cases
$perl_var = {
	# even keys are checked, so use a number for a key too!
	'123' => [1,2,3,123],
};
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'strings'=>0,
	'numbers'=>0,
}) == 0, "check_content_recursively() : looked for nothing."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'strings'=>1, # looking for strings?
	'numbers'=>0, # not looking for numbers
}) == 0, "check_content_recursively() : strings: no, numbers did not check"); $num_tests++;
# empty params
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
}) == 0, "check_content_recursively() : did not check for anything"); $num_tests++;
# undef params
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, undef
) == 0, "check_content_recursively() : did not check for anything"); $num_tests++;
# no params
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var,
) == 0, "check_content_recursively() : did not check for anything"); $num_tests++;

#####
# complex data structures with only unicode
$perl_var = {
	'χυζ' => 'αβγ',
	'αβγ' => {
		'αβγ' => 'βγ',
		'χυζ' => ['α', 'β'],
	},
	'κιαθ' => ['ά', 'Ά', 'Α', 'Ζ'],
};
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 0, "check_content_recursively() : numbers:  yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings'=>1,
}) == 1, "check_content_recursively() : strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>1,
	'strings-plain'=>0,
}) == 1, "check_content_recursively() : unicode strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>0,
	'strings-plain'=>1,
}) == 0, "check_content_recursively() : non-unicode strings: no."); $num_tests++;

#####
# complex data structures with no unicode
$perl_var = {
	'abc' => 'hdhd',
	'xyz' => {'ahah'=>'ssjs', 'zhahah'=>['a','b','aaaa']},
	'uauau' => ['aaaa','bbbb'],
};
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>1,
	'strings'=>0,
}) == 0, "check_content_recursively() : numbers:  yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings'=>1,
}) == 1, "check_content_recursively() : strings: yes."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>1,
	'strings-plain'=>0,
}) == 0, "check_content_recursively() : unicode strings: no."); $num_tests++;
ok(Data::Random::Structure::UTF8::check_content_recursively($perl_var, {
	'numbers'=>0,
	'strings-unicode'=>0,
	'strings-plain'=>1,
}) == 1, "check_content_recursively() : non-unicode strings: yes."); $num_tests++;

done_testing($num_tests);

use Acme::Test::42 qw(no_plan);

use strict;

ok(42, 'Bare 42');
ok("42", '42 as a string');
ok(42.0, '42 as a number');

not_ok(42.01, 'Above');
not_ok(41.99, 'Below');

ok(answer_to_the_ultimateq_question_of_life_the_universe_and_everything(), 'Answer to the Ultimate Question of Life, the Universe, and Everything');

sub answer_to_the_ultimateq_question_of_life_the_universe_and_everything {
    42
}

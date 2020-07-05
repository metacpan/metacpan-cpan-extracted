use warnings;
use strict;

use Test::More;

plan tests => 10;

use Code::ART;

ok !eval{ refactor_to_sub() }                                       => 'Missing first argument';
like $@, qr{'code' argument of refactor_to_sub\(\) must be a string} => '...produced correct message';

ok !eval{ refactor_to_sub([]) }                                     => 'Wrong first argument';
like $@, qr{'code' argument of refactor_to_sub\(\) must be a string} => '...produced correct message';

ok !eval{ refactor_to_sub('', [ naem => 'refsub' ]) }               => 'Wrong second argument';
like $@, qr{'options' argument of refactor_to_sub\(\) must be hash ref, not array ref}
                                                                    => '...produced correct message';

ok !eval{ refactor_to_sub('', 'oops', { naem => 'refsub' }) }       => 'Bad argument';
like $@, qr{Unexpected extra argument passed to refactor_to_sub\(\): 'oops'}
                                                                    => '...produced correct message';

ok !eval{ refactor_to_sub('', { naem => 'refsub' }) }               => 'Bad option';
like $@, qr{Unknown option \('naem'\) passed to refactor_to_sub}    => '...produced correct message';


done_testing();


use warnings;
use strict;

use Test::More;

plan tests => 1;

use Code::ART;

my $refactoring;

subtest 'Invalid code' => sub {
    $refactoring = refactor_to_sub(
        'say 1; $not $valid $perl', {from=>0, to=>23}
    );

    ok exists $refactoring->{failed}                     => 'Failure key returned';
    like $refactoring->{failed}, qr/invalid source code/ => 'Error message as expected';
    is $refactoring->{context}, '$not $valid $perl'      => 'Right context';
};

done_testing();


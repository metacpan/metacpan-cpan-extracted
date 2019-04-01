#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Acme::Affinity';

my $affinity = eval { Acme::Affinity->new };
isa_ok $affinity, 'Acme::Affinity';
ok !$@, 'created with no arguments';

my $questions = [
    { 'how messy are you' => [ 'very messy', 'average', 'very organized' ] },
    { 'do you like to be the center of attention' => [ 'yes', 'no' ] },
];
my $importance = {
    'irrelevant'         => 0,
    'a little important' => 1,
    'somewhat important' => 10,
    'very important'     => 50,
    'mandatory'          => 250,
};
my $me = [
    [ 'very organized', 'very organized', 'very important' ],
    [ 'no',             'no',             'a little important' ],
];
my $you = [
    [ 'very organized', 'average', 'a little important' ],
    [ 'yes',            'no',      'somewhat important' ],
];

$affinity = Acme::Affinity->new(
    questions  => $questions,
    importance => $importance,
    me         => $me,
    you        => $you,
);

is_deeply $affinity->questions, $questions, 'questions';
is_deeply $affinity->importance, $importance, 'importance';
is_deeply $affinity->me, $me, 'me';
is_deeply $affinity->you, $you, 'you';

my $score = $affinity->score();
is sprintf( '%.2f', $score ), 94.41, 'score';

$me = [
    [ 'very organized', 'very organized', 'very important' ],
    [ 'no',             'no',             'a little important' ],
];
$you = [
    [ 'very organized', 'very organized', 'very important' ],
    [ 'no',             'no',             'very important' ],
];

$affinity = Acme::Affinity->new(
    questions  => $questions,
    importance => $importance,
    me         => $me,
    you        => $you,
);

$score = $affinity->score();
is $score, 100, 'score';

$me = [
    [ 'very organized', 'very organized', 'very important' ],
    [ 'no',             'no',             'a little important' ],
];
$you = [
    [ 'very messy', 'very messy', 'irrelevant' ],
    [ 'yes',        'yes',        'very important' ],
];

$affinity = Acme::Affinity->new(
    questions  => $questions,
    importance => $importance,
    me         => $me,
    you        => $you,
);

$score = $affinity->score();
is $score, 0, 'score';

done_testing();

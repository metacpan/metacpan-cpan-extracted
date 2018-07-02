#!perl

use strict;
use warnings;
use Test::More;

sub dies_like (&$$) { ## no critic
    my ($block, $exp, $comment) = @_;

    my ($file, $line) = (caller 0)[1,2];
    $line = join "|", map { $line + $_ } -1 .. 1;
    my $where = $] < 5.008 ? '.*' : "\Q$file\E line (?:$line)\.?";

    my $res = eval {
        $block->();
        1;
    };

    if ($exp) {
        like $@, qr/$exp.*$where$/, $comment;
        note "Exception was: $@";
    } else {
        ok $res, $comment or diag "Died unexpectedly: $@";
    };
};

use Assert::Refute qw(:core);

my $c = contract{} args => 3;

dies_like {
    $c->apply(1..2);
} qr/expected.*3.*parameters/, "const - less";
dies_like {
    $c->apply(1..3);
} "", "const - exact";
dies_like {
    $c->apply(1..4);
} qr/expected.*3.*parameters/, "const - more";

$c = contract{} args => [3,-1];

dies_like {
    $c->apply(1..2);
} qr/expected.*3.*parameters/, "inf - less";
dies_like {
    $c->apply(1..3);
} "", "inf - exact";
dies_like {
    $c->apply(1..4);
} "", "inf - more";

$c = contract{} args => [3,4];

dies_like {
    $c->apply(1..2);
} qr/expected.*3.*4.*parameters/, "var - less";
dies_like {
    $c->apply(1..3);
} "", "var - lower";
dies_like {
    $c->apply(1..4);
} "", "var - upper";
dies_like {
    $c->apply(1..5);
} qr/expected.*3.*4.*parameters/, "var - more";

dies_like {
    $c = contract {} args => [5,2];
} qr/limit/, "Rubbish in args";

done_testing;

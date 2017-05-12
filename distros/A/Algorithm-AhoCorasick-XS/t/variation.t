use strict;
use warnings;
use Test::More 0.96;

use Algorithm::AhoCorasick::XS;
use Data::Dump qw(dump);
use List::Util qw(shuffle);

my @strings = (
    '0',
    'x',
    'xy',
    'xyz',
    'xyzb',
    'xyza',
    'xyzbq',
    'q',
    'w',
    'qw',
    'qwerty',
    'qwertyuiop',
    'qwertyfoo',
);

my @inputs = (
    '',
    'p',
    "\0",
    0,
    @strings,
);
push @inputs, map {"x$_"}  @strings,
push @inputs, map {"$_$_"} @strings;
push @inputs, map {$_."x"} @strings;
foreach my $len (1..4) {
    push @inputs, map {substr($_,0,$len).$_} @strings;
}
push @inputs, join "q", @strings;
push @inputs, join "",  @strings;
push @inputs, join "q", reverse @strings;
push @inputs, join "",  reverse @strings;
push @inputs, join "q", shuffle @strings;
push @inputs, join "",  shuffle @strings;

my @string_sets = map {[$_]} @strings;
push @string_sets, \@strings;

foreach my $set (@string_sets) {
    my $m = Algorithm::AhoCorasick::XS->new($set);
    foreach my $input (@inputs) {
        my @want = sort grep { index($input, $_) != -1 } @$set;
        my @got = $m->unique_matches($input);
        @got = sort @got;
        unless (is_deeply \@got, \@want) {
            diag "input was [$input]";
            diag "str set was ".join(',', @$set);
            diag "got: ". dump(@got);
            diag "want ". dump(@want);
        }
    }
}

done_testing;

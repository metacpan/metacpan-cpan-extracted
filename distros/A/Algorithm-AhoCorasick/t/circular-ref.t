use strict;
use warnings;
use Test::More;

eval { require Test::Memory::Cycle; };

if ($@) {
    plan skip_all => 'Test::Memory::Cycle required to test circular references';
}

plan tests => 3;
Test::Memory::Cycle->import;

use_ok 'Algorithm::AhoCorasick';
    
do {
    my $aho = Algorithm::AhoCorasick::SearchMachine->new([qw(foo)]);
    memory_cycle_ok($aho, "SearchMachine is instantiated without circular references ok");
};

do {
    my $aho = Algorithm::AhoCorasick::SearchMachine->new([qw(foo)]);
    my %results;
    $aho->feed("Monkey chicken foo", sub {
        my ($pos, $keyword) = @_;
        push @{$results{$pos}}, $keyword;
        undef;
    });
    memory_cycle_ok($aho, "SearchMachine did not gain any circular references from feed ok");
};


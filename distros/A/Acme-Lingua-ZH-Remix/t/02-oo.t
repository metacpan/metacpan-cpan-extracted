#!/usr/bin/env perl
use Test::More;
use strict;
use utf8;
use Acme::Lingua::ZH::Remix;

subtest 'split_corpus method' => sub {
    my $r = Acme::Lingua::ZH::Remix->new;
    my @phrases = sort $r->split_corpus(q(還不賴！總之，很好。如何？));
    my @answer  = sort qw(還不賴！ 總之， 很好。 如何？);

    is_deeply(\@phrases, \@answer);

    done_testing;
};

subtest 'a simple one' => sub {
    my $r = Acme::Lingua::ZH::Remix->new;
    ok($r->phrase_count > 4, "phrase_count seems to be correct");

    for(1..100) {
        my $s = $r->random_sentence;
        utf8::encode($s);
        ok $s, "something is generated: $s";
    }

    done_testing;
};

subtest 'custom phrase materials' => sub {
    my $r = Acme::Lingua::ZH::Remix->new;
    $r->feed("還不賴！ 總之， 很好。 如何？");
    is ($r->phrase_count, 4, "phrase_count is correct");

    for(1..100) {
        my $s = $r->random_sentence;
        utf8::encode($s);
        ok $s, "something is generated: $s";
    }

    done_testing;
};

done_testing;


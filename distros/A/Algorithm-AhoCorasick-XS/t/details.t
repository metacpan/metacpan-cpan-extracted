use strict;
use warnings;
use Test::More 0.96;
use Algorithm::AhoCorasick::XS;

subtest details => sub {
    my $ac = Algorithm::AhoCorasick::XS->new([qw(he she hers his)]);
    my @details = $ac->match_details("ahishers");

    is( $details[0]{word}, "his" );
    is( $details[0]{start}, 1 );
    is( $details[0]{end}, 3 );

    is( $details[1]{word}, "she" );
    is( $details[1]{start}, 3 );
    is( $details[1]{end}, 5 );

    is( $details[2]{word}, "he" );
    is( $details[2]{start}, 4 );
    is( $details[2]{end}, 5 );

    is( $details[3]{word}, "hers" );
    is( $details[3]{start}, 4 );
    is( $details[3]{end}, 7 );
};

subtest empty => sub {
    my $ac = Algorithm::AhoCorasick::XS->new([qw(he she hers his)]);
    my @details = $ac->match_details("xyxyxyxyxyxyxy");
    is_deeply( \@details, [] );
};

done_testing;

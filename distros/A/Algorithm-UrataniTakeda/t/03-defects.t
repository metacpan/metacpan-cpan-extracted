#!perl

use v5.26;

use Test2::V0 -no_srand => 1;
use Test2::Tools::Compare qw( bag );
use Test2::Tools::Exception qw( lives );

use Algorithm::UrataniTakeda v0.1.3;

use experimental qw( signatures );

subtest "non-termination" => sub {

    my $m = Algorithm::UrataniTakeda->new( patterns => [ "a", "bcd" ] );

    my $timed_out;
    ok( lives {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 5;
        is [ $m->matches("zzzzz") ], [], 'match failed as expected';
        alarm 0;
        }, "does not hang" ) or note $@;
    alarm 0;

};

subtest "false positives" => sub {

    my $m = Algorithm::UrataniTakeda->new( patterns => [ "ab", "bab" ] );

    is match_details( $m, "ab" ), as_bag(
        [ 0, "ab" ],
    );

    is match_details( $m, "zzab" ), as_bag(
        [ 2, "ab" ],
    );

};

subtest "missed match" => sub {

    my $m = Algorithm::UrataniTakeda->new( patterns => [ "aaaa", "abab" ] );

    is match_details( $m, "aaabab" ), as_bag(
        [ 2, "abab" ],
    );

};

subtest "missed suffix" => sub {

    my $m = Algorithm::UrataniTakeda->new( patterns => [ "attack", "tack" ] );

    is match_details( $m, "attack" ), as_bag(
        [ 0, "attack" ],
        [ 2, "tack" ],
    );

};

subtest "small strings" => sub {

    my $m = Algorithm::UrataniTakeda->new( patterns => [ "a", "ba" ] );

    is match_details( $m, "abba" ), as_bag(
        [ 0, "a" ],
        [ 2, "ba" ],
        [ 3, "a" ],
    );

    is match_details( $m, "abracadabra" ), as_bag(
        [ 0, "a" ],
        [ 3, "a" ],
        [ 5, "a" ],
        [ 7, "a" ],
        [ 10, "a" ],
    );

};

subtest "duplicate keywords" => sub {

    my $m = Algorithm::UrataniTakeda->new( patterns => [ "foo", "bar", "foo" ] );

    is match_details( $m, "dogfood" ), as_bag(
        [ 3, "foo" ],
    );


    is match_details( $m, "dogfood is food" ), as_bag(
        [ 3, "foo" ],
        [ 11, "foo" ],
    );


};

subtest "zero" => sub {

    my $m = Algorithm::UrataniTakeda->new( patterns => [ "0" ] );

    is match_details( $m, "d0g" ), as_bag(
        [ 1, "0" ],
    );

};


sub as_bag(@list) {

    my $arr = Test2::Compare::Bag->new;
    $arr->add_item($_) for @list;
    $arr->set_ending(1);

    return $arr;
}

sub match_details( $m, $text ) {

    my @output;

    $m->search(
        $text,
        sub( $pos, $phrase ) {
            push @output, [ $pos, $phrase ];
            return 1;
        }
    );

    return \@output;
}

done_testing;

use strict;
use warnings;
use utf8;
use Test::More 0.96;
use Algorithm::AhoCorasick::XS;
use Encode qw(decode);

# Test how the module handles strings with wide characters.
my $string = "明日、今日よりも好きになれる　溢れる思いが止まらない";
my @words = ("明日", "なれる", "よる", "ぬ");

my $matcher = Algorithm::AhoCorasick::XS->new(\@words);
my @found = $matcher->matches($string);

is( scalar @found, 2 );
is( decode('UTF-8', $found[0]), "明日" );
is( decode('UTF-8', $found[1]), "なれる" );

my @details = $matcher->match_details($string);
is( scalar @details, 2 );
for my $d (@details) {
    is( $d->{word}, bytes::substr($string, $d->{start}, $d->{end} - $d->{start} + 1) );
}

done_testing;

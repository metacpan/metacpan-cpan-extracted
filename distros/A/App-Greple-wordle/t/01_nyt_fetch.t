use v5.14;
use warnings;
use Test::More 0.98;

use lib 'lib';
use HTTP::Tiny;
use App::Greple::wordle::NYT;

my @urls;
my $response;

no warnings 'redefine';
local *HTTP::Tiny::get = sub {
    my($self, $url) = @_;
    push @urls, $url;
    $response;
};
use warnings 'redefine';

sub fetch {
    my($index, $res) = @_;
    @urls = ();
    $response = $res;
    App::Greple::wordle::NYT::fetch_answer($index);
}

sub ok_json {
    { success => 1, status => 200, content => shift };
}

is fetch(0, ok_json '{"id":1,"solution":"cigar","print_date":"2021-06-19"}'),
    'cigar', 'answer without days_since_launch';
is_deeply \@urls, [ 'https://www.nytimes.com/svc/wordle/v2/2021-06-19.json' ],
    'index 0 is 2021-06-19';

is fetch(1700, ok_json '{"solution":"CIGAR","days_since_launch":1700}'),
    'cigar', 'answer is lower-cased';
is_deeply \@urls, [ 'https://www.nytimes.com/svc/wordle/v2/2026-02-13.json' ],
    'index 1700 is 2026-02-13';

is fetch(1700, ok_json '{"solution":"cigar","days_since_launch":1699}'),
    undef, 'days_since_launch mismatch';

is fetch(1700, { success => 0, status => 599, content => 'no ssl' }),
    undef, 'request failure';

is fetch(1700, ok_json '<html>'), undef, 'broken json';

is fetch(1700, ok_json '{"solution":"cigars"}'), undef, 'not a five-letter word';

is fetch(1_000_000, ok_json '{"solution":"cigar"}'), undef, 'future index';
is scalar @urls, 0, 'no request for future index';

is fetch(-1, ok_json '{"solution":"cigar"}'), undef, 'negative index';
is scalar @urls, 0, 'no request for negative index';

done_testing;

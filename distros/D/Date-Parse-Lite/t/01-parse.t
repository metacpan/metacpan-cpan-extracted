#!perl -T
use 5.008_001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 9504;

use Date::Parse::Lite;

my $parser = Date::Parse::Lite->new();
ok($parser->prefer_month_first_order, "Defaults to prefer_month_first_order");

my $this_year = 1900 + (localtime)[5];
my @two_digit_year_fixtures = (
    [ ($this_year     )  % 100  => $this_year      ],
    [ ($this_year +  1)  % 100  => $this_year +  1 ],
    [ ($this_year + 50)  % 100  => $this_year + 50 ],
    [ ($this_year + 51)  % 100  => $this_year - 49 ],
    [ ($this_year -  1)  % 100  => $this_year -  1 ],
    [ ($this_year - 51)  % 100  => $this_year + 49 ],
    [ ($this_year - 50)  % 100  => $this_year + 50 ],
    [ ($this_year - 49)  % 100  => $this_year - 49 ],
);

my $ten_years_forward = $this_year + 10;
my $ten_years_back = $this_year - 10;

my $fixtures = <<EOT;
24/1/1995:1995:01:24T09:08:17.1823213 ISO-8601
24/1/1995:1995-01-24T09:08:17.1823213
16/6/1994:Wed, 16 Jun 1994 07:29:35 CST 
13/10/1994:Thu, 13 Oct 1994 10:13:13 -0700
9/11/1994:Wed, 9 Nov 1994 09:50:32 -0500 (EST) 
21/12/1917:21 dec 1917:05 
21/12/1917:21-dec 1917:05
21/12/1917:21/dec 1917:05
21/12/1993:21/dec/1993 17:05
2/10/1999:1999 10:02:18 "GMT"
16/11/1994:16 Nov 1994 22:28:20 PST
10/11/2012:10 th Nov 2012
10/11/2012:10 Nov 2012
10/11/2012:Nov 10 th 2012
10/11/2012:Nov 10th 2012
10/11/2012:Nov 10 2012
10/11/2012:20121110
9/11/1910:9Nov1910
10/9/1911:9-10-1911
14/9/1911:14-9-1911
:23-23-11
:12Jib2012
:32Feb2012
1/2/1903:1February1903
:jafdhsj
EOT

test_date_parser($parser, $_) foreach (split "\n", $fixtures);

my $this_year_two = sprintf "%02i", $this_year % 100;
$fixtures = <<EOT;
24/1/1995:1995:01:24T09:08:17.1823213 ISO-8601
24/1/1995:1995-01-24T09:08:17.1823213
16/6/1994:Wed, 16 Jun 1994 07:29:35 CST 
13/10/1994:Thu, 13 Oct 1994 10:13:13 -0700
9/11/1994:Wed, 9 Nov 1994 09:50:32 -0500 (EST) 
21/12/1917:21 dec 1917:05 
21/12/1917:21-dec 1917:05
21/12/1917:21/dec 1917:05
21/12/1993:21/dec/1993 17:05
2/10/1999:1999 10:02:18 "GMT"
16/11/1994:16 Nov 1994 22:28:20 PST
10/11/2012:10 th Nov 2012
10/11/2012:10 Nov 2012
10/11/2012:Nov 10 th 2012
10/11/2012:Nov 10th 2012
10/11/2012:Nov 10 2012
10/11/2012:20121110
9/11/$this_year:9Nov$this_year_two
9/10/$this_year:9-10-$this_year_two
14/9/$this_year:14-9-$this_year_two
:23-23-11
:12Jib2012
:32Feb2012
1/2/1903:1February1903
:jafdhsj
EOT

$parser->prefer_month_first_order(0);
test_date_parser($parser, $_) foreach (split "\n", $fixtures);

foreach my $day (qw(1 9 10 11 19 21 28 31)) {
    foreach my $month (1 .. 12) {
        foreach my $year (qw(100 999 1000 1999 2000 2100)) {
            my $expected = "$day/$month/$year";
            $parser->prefer_month_first_order(1);
            test_date_parser($parser, "$expected:$month/$day/$year");
            test_date_parser($parser, sprintf "$expected:%04i%02i%02i", $year, $month, $day);
            $parser->prefer_month_first_order(0);
            test_date_parser($parser, "$expected:$day/$month/$year");
            test_date_parser($parser, sprintf "$expected:%04i%02i%02i", $year, $month, $day);
        }
    }
}

use utf8;
my $non_ascii_month = 'áéíóú';
no utf8;

$fixtures = <<"EOT";
1/1/2015:1firstmonth2015
1/1/2015:1primero2015
20/12/2015:20lastmonth2015
20/12/2015:20doce2015
20/3/2015:20${non_ascii_month}2015
EOT

foreach my $fixture (split "\n", $fixtures) {
    $fixture =~ /:(.+)$/;
    test_date_parser($parser, ":$1");
}


$parser->month_names(firstmonth => 1);
$parser->month_names(primero => 1, lastmonth => 12, doce => 12, ${non_ascii_month} => 3);

no utf8;

test_date_parser($parser, $_) foreach (split "\n", $fixtures);

foreach my $two_digit_year_fixture (@two_digit_year_fixtures) {
    my($test_year, $expected_year) = @$two_digit_year_fixture;
    test_date_parser($parser, "21/6/$expected_year:21/06/$test_year");
    $parser->literal_years_below_100(1);
    test_date_parser($parser, "21/6/$test_year:21/06/$test_year");
    $parser->literal_years_below_100(0);
}

$parser = Date::Parse::Lite->new(
    prefer_month_first_order => 0,
    literal_years_below_100  => 1,
    month_names              => [ first => 1, last => 12 ],
    date                     => '2/3/4',
);
is($parser->month, 3, "Can initialise prefer_month_first_order");
is($parser->year,  4, "Can initialise literal_years_below_100");
$fixtures = <<EOT;
1/1/15:1first15
1/2/2015:1/2/2015
20/12/15:20last15
20/12/15:12/20/15
20/12/2015:20last2015
EOT
test_date_parser($parser, $_) foreach (split "\n", $fixtures);

sub test_date_parser {
    my($parser, $fixture) = @_;

    my($date, $string) = split m{\s*:\s*}, $fixture, 2;
    my($d, $m, $y) = split m{\s*/\s*}, $date;
    $parser->parse($string);
    if($parser->parsed) {
        ok($date ne '', "parsed, as expected: $string");
        is($parser->day, $d, "Extracted day '$d': $string");
        is($parser->month, $m, "Extracted month '$m': $string");
        is($parser->year, $y, "Extracted year '$y': $string");
    }
    else {
        ok($date eq '', "parse fail was expected: $string");
    }
}



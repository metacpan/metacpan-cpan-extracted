#!perl -T

use Test::More 'no_plan';

use Convert::Age qw(encode_age decode_age);

my @data = qw(
    285
    4m45s
    216
    3m36s
    189985765
    6y7d10h54m13s
    189985765
    6y7d10h54m13s
    189985771
    6y7d10h54m19s
    458
    7m38s
    344
    5m44s
    22906
    6h21m46s
    22877
    6h21m17s
    61488
    17h4m48s
    189985765
    6y7d10h54m13s
);

for my $f ( 3600*2 .. 3600 * 2 + 10 ) {
    my $enc = encode_age($f);
    my $dec = decode_age($enc);

    ok($f == $dec, "$f == $enc == $dec");
}

while(my ($i, $j) = splice(@data, 0, 2)) {
    ok( $i == decode_age($j),  "$i == decode_age( $j ) == ". decode_age($j));
    ok( $j eq encode_age($i), "$j == encode_age ( $i ) == ". encode_age($i));
}

diag( "Testing Convert::Age $Convert::Age::VERSION, Perl $], $^X" );

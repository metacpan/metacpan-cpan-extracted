use Test::More tests => 72;
use Test::Exception;

use Acme::Geo::Whitwell::Name;

# Numbers < -180 or > 180 die.
dies_ok { Acme::Geo::Whitwell::Name::_two_decimal(-500) }
        "< -180 dies";
dies_ok { Acme::Geo::Whitwell::Name::_two_decimal(500) }
        ">180 dies";

my $two_digit;

my @in  = qw( 0    10    10.0  10.00 100.0000 000000000 -100.0);
my @out = qw( 0.00 10.00 10.00 10.00 100.00   0.00      100.00 );
while (@in) {
    my $number = shift @in;
    my $answer = shift @out;
    foreach my $suffix ('', qw(N S W E)) {
        $two_digit = Acme::Geo::Whitwell::Name::_two_decimal("$number$suffix");
        ok $two_digit, "Converted $number$suffix to $two_digit";
        is $two_digit, $answer, "Got expected value $answer";
    }
}

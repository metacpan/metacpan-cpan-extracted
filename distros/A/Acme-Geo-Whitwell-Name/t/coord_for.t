use Test::More;

eval "use Test::Exception";
my $skip_exceptions = $@;

use Test::Exception;
use Acme::Geo::Whitwell::Name;

my %tests = (
    "ou" => ['0.00', 0],
    "eenoup" => [77.08, 0],
    "eeseetei" => [77.08, 1],
    "beef" =>     [1.73, 0],
    "beevi" => [1.73, 1],
);

plan tests => 2+(2 * int keys %tests);

foreach (keys %tests) {
    my($value, $sign) = Acme::Geo::Whitwell::Name::_coord_for($_);
    is $tests{$_}->[0], $value,
       "$_ converted to $tests{$_}->[0]";
    is $tests{$_}->[1], $sign,
       "sign detected";
}

# Exceptions: bad characters and bad sequencing.
SKIP: {
  skip "Test::Exception not installed", 1 if $skip_exceptions;
  dies_ok {  Acme::Geo::Whitwell::Name::_coord_for("blargh") }
        'bad string dies';
}

SKIP: {
  skip "Test::Exception not installed", 1 if $skip_exceptions;
  dies_ok { Acme::Geo::Whitwell::Name::_coord_for("eeeeeeee") }
        'badly-formed string dies';
}

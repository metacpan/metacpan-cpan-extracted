use strict;
use warnings;
use Test::More;
use Acme::Kensiro;

my @tests = (
    0, 'た',
    1, 'あ',
    2, 'あた',
    16, 'あたたたた',
    256, 'あたたたたたたたた',
    8192, 'あたたたたたたたたたたたたた',
    2147483648, 'あたたたたたたたたたたたたたたたたたたたたたたたたたたたたたたた',
    4294967295, 'ああああああああああああああああああああああああああああああああ',
);
while (my ($input, $expected) = splice @tests, 0, 2) {
    is(kensiro($input), $expected, "IN: $input");
}

done_testing;

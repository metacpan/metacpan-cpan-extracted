#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::Phone' );
}

my $module = 'Data::Validate::WithYAML::Plugin::Phone';

my @phones = (
    '+4412345677',
    '004412345677',
    '0157124567889',
    '+1 555 13351 13',
    '0177 - 123456789',
    '+49 177 - 123456789',
    '+49 177 / 124532344',
    '0177 / 1234392',
    '0211 5110',
    '+49 211 5110',
    '+49 211 / 5110',
    '+49 211 - 5110',
    '+1234567',
);

my @blacklist = (
    'test',
    '123',
    '+12as',
    '00012345678',
    '+012455678832',
);

for my $phone ( @phones ){
    ok( $module->check($phone), "test: $phone" );
}

for my $check ( @blacklist ){
    my $retval = $module->check( $check );
    ok( !$retval, "test: $check" );
}

done_testing();

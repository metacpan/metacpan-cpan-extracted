#!perl -T

use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::IBAN' );
}

my $module = 'Data::Validate::WithYAML::Plugin::IBAN';

my @ibans = (
    'CH41 0900 0000 9000 4135 9',
    'CH71 0076 9016 1472 4711 6',
    'IT 50 H 01030 70700 000000241580',
    'CH63 0078 8000 L115 0969 0',
    'DE28 8005 5008 3320 0020 06',
    'DE83 8005 5008 3340 0022 22',
    'DE50 4605 1240 0001 0000 58',
    'DE45 5455 0010 0000 0001 66',
);

my @blacklist = (
    'CH41 0900 0000 9000 4135 5',
    'CH71 0076 9016 1472 4711 1',
    'IT50 L060 4558 2200 0000 50421',
    'CH63 0078 8000 L115 0969 77',
    'DE28 8005 5008 3320',
    'DE0815',
);


for my $iban ( @ibans ){
    ok( $module->check($iban), "test: $iban" );
}

for my $check ( @blacklist ){
    my $retval = $module->check( $check );
    ok( !$retval, "test: $check" );
}

done_testing();

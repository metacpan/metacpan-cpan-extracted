#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::EMail' );
}

my $module = 'Data::Validate::WithYAML::Plugin::EMail';

my @emails = (
    'module@renee-baecker.de',
    'test@example.org',
    'my_address@test.example.org',
    'my.address@test.example.org',
    '123@example.org',
    'address@123.81.31.255',
    'address@anything',
    '^&@example.org',
);

my @blacklist = (
    'test',
    '123',
    'irgendwas.de',
);

for my $mail ( @emails ){
    ok( $module->check($mail) );
}

for my $check ( @blacklist ){
    my $retval = $module->check( $check );
    ok( !$retval );
}

my $error;
eval {
    $module->check( undef );
    1;
} or $error = $@;

like $error, qr/no value to check/;

done_testing();

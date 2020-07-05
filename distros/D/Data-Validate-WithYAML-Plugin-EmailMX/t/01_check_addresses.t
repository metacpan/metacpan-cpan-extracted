#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Data::Validate::WithYAML::Plugin::EmailMX' );
}

my $module = 'Data::Validate::WithYAML::Plugin::EmailMX';

my @emails = (
    'cpan-tests@perl-services.de',
    'cpan-tests@mailinator.com',
    'cpan-tests@testmail.app',
);

my @blacklist = (
    'test@example.org',
    '123@example.org',
    'address@123.81.31.255',
    'my_address@test.example.org',
    'my.address@test.example.org',
    'module@renee-baecker.de',
    '^&@example.org',
    'test',
    '123',
    'irgendwas.de',
    'address@anything',
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

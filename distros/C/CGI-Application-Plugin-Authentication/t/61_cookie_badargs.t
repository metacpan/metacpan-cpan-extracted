#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t);

use CGI::Util;

use Test::More;
use Test::NoWarnings;

plan tests => 2;

{

    package TestAppStoreCookie;
    use Test::More;
    use Test::Exception;

    use base qw(TestAppStore);

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { 'test' => '123' } ],
        STORE  => [ 'Cookie', EXPIRY=>'+1y', 'YAH_BOO_SUCKS'],
        CREDENTIALS => [qw(auth_username auth_password)],
    );

    sub run_store_tests {
        my $class = shift;
        my ( $cgiapp, $results, $store_entries );

        # Regular call to unprotected page shouldn't create a store entry
        throws_ok {
            ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'unprotected' } );
        } qr/Error executing run mode 'unprotected': Invalid Store Configuration for the Cookie store - options section must contain a hash of values/, 'invalid args';
}

}


TestAppStoreCookie->run_store_tests;



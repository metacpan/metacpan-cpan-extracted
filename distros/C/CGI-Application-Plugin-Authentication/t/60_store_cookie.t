#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t);

use CGI::Util;

use Test::More;

plan tests => 17;

{

    package TestAppStoreCookie;

    use base qw(TestAppStore);

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { 'test' => '123' } ],
        STORE  => [ 'Cookie', SECRET => "Shhh, don't tell anyone", NAME => 'CUSTOM_NAME', EXPIRY => '+1y' ],
        CREDENTIALS => [qw(auth_username auth_password)],
    );

    sub get_store_entries {
        my $class = shift;
        my $cgiapp = shift;
        my $results = shift;

        my ($capauth_data, $therest) = $results =~ qr/^Set\-Cookie:\s+CUSTOM_NAME=([\d\w%]+);(.*)$/m;
        return undef unless $capauth_data;
        main::like($therest, qr/expires=/, 'Expiry on the cookie is set');
        my $data = CGI::Util::unescape($capauth_data);
        return $data ? $cgiapp->authen->store->_decode($data) : undef;
    }

    sub maintain_state {
        my $class = shift;
        my $old_cgiapp = shift;
        my $old_results = shift;
        my $new_query = shift;

        delete $ENV{'COOKIE'};
        $old_results =~ qr/Set\-Cookie:\s+(CUSTOM_NAME=[\d\w%]+);/;
        $ENV{'COOKIE'} = $1 if $1;
    }

    sub clear_state {
        my $class = shift;
        delete $ENV{'COOKIE'};
        $class->SUPER::clear_state(@_);
    }

}


TestAppStoreCookie->run_store_tests;



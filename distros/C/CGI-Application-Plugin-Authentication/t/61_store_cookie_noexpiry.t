#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t);
use Readonly;
Readonly my $SECRET_WARN => qr/using default SECRET\!  Please provide a proper SECRET when using the Cookie store/;
use Test::NoWarnings;

use CGI::Util;

use Test::More;

plan tests => 21;

{

    package TestAppStoreCookie;
    use Test::More;
    use Test::Warn;

    use base qw(TestAppStore);

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { 'test' => '123' } ],
        STORE  => [ 'Cookie'],
        CREDENTIALS => [qw(auth_username auth_password)],
    );

    sub get_store_entries {
        my $class = shift;
        my $cgiapp = shift;
        my $results = shift;

        my ($capauth_data, $therest) = $results =~ qr/^Set\-Cookie:\s+CAPAUTH_DATA=([\d\w%]+);(.*)$/m;
        return undef unless $capauth_data;
        main::unlike($therest, qr/expires=/, 'Expiry on the cookie is not set');
        my $data = CGI::Util::unescape($capauth_data);
        return $data ? $cgiapp->authen->store->_decode($data) : undef;
    }

    sub maintain_state {
        my $class = shift;
        my $old_cgiapp = shift;
        my $old_results = shift;
        my $new_query = shift;

        delete $ENV{'COOKIE'};
        $old_results =~ qr/Set\-Cookie:\s+(CAPAUTH_DATA=[\d\w%]+);/;
        $ENV{'COOKIE'} = $1 if $1;
    }

    sub clear_state {
        my $class = shift;
        delete $ENV{'COOKIE'};
        $class->SUPER::clear_state(@_);
    }

    sub run_store_tests {
        my $class = shift;
        my ( $cgiapp, $results, $store_entries );

        # Regular call to unprotected page shouldn't create a store entry
        ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'unprotected' } );
        ok(!$store_entries, "Store entry not created when calling unprotected page" );

        # Regular call to protected page (without a valid login) shouldn't create a store entry
        ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'protected' } );
    ok(!$store_entries, "Store entry not created when calling protected page without valid login" );

    # Regular call to protected page (with an invalid login) should create a store entry marking login attempts
    warnings_like {
        ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'protected', auth_username => 'test', auth_password => 'badpassword' } );
    } [$SECRET_WARN, $SECRET_WARN], 'bad SECRET warning';
    ok(!$cgiapp->authen->is_authenticated,'failed login attempt');
    ok($store_entries, "Store entry created when calling protected page with invalid login" );
    isnt($store_entries->{username}, 'test', "Store entry contained the right username" );
    is($store_entries->{login_attempts}, 1, "Store entry contained the right value for login_attempts" );

    # Regular call to protected page (with an invalid login) should create a store entry marking login attempts
    warnings_like {
        ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'protected', auth_username => 'test', auth_password => 'badpassword' } );
    } [$SECRET_WARN, $SECRET_WARN, $SECRET_WARN], 'bad SECRET warning';
    ok(!$cgiapp->authen->is_authenticated,'failed login attempt');
    ok($store_entries, "Store entry created when calling protected page with invalid login" );
    isnt($store_entries->{username}, 'test', "Store entry contained the right username" );
    is($store_entries->{login_attempts}, 2, "Store entry contained the right value for login_attempts" );

    # Regular call to protected page (with a valid login) should create a store entry
    warnings_like {
        ($cgiapp, $results, $store_entries) = $class->run_app( { rm => 'protected', auth_username => 'test', auth_password => '123' } );
    } [$SECRET_WARN, $SECRET_WARN, $SECRET_WARN], 'bad SECRET warning';
    ok($cgiapp->authen->is_authenticated,'successful login');
    ok($store_entries, "Store entry created when calling protected page with valid login" );
    is($store_entries->{username}, 'test', "Store entry contained the right username" );
    ok(!$store_entries->{login_attempts}, "Store entry cleared login_attempts" );

}

}


TestAppStoreCookie->run_store_tests;



#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t);

use CGI::Util;

use Test::More;
use Test::Exception;
plan tests => 17;

our %STORAGE;

{

    package TestAppStoreDummy;

    use base qw(TestAppStore);

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { 'test' => '123' } ],
        STORE  => [ 'Store::Dummy', \%STORAGE ],
        CREDENTIALS => [qw(auth_username auth_password)],
    );

    sub get_store_entries {
        return %STORAGE ? \%STORAGE : undef;
    }

#--------------------------------------------------
#     sub maintain_state {
#         my $class = shift;
#         my $old_cgiapp = shift;
#         my $old_results = shift;
#         my $new_query = shift;
#     }
#-------------------------------------------------- 

    sub clear_state {
        my $class = shift;
        my $old_cgiapp = shift;
        my $old_results = shift;
        delete $STORAGE{$_} foreach keys %STORAGE;
    }

}


TestAppStoreDummy->run_store_tests;

# Test some methods that should never be called
my $store = TestAppStoreDummy->new->authen->store;
throws_ok { $store->CGI::Application::Plugin::Authentication::Store::fetch('username') } qr/fetch must be implemented in the/, 'Store dies when fetch is called without being overridden in the subclass';
throws_ok { $store->CGI::Application::Plugin::Authentication::Store::save(username => 'test1') } qr/save must be implemented in the/, 'Store dies when save is called without being overridden in the subclass';
throws_ok { $store->CGI::Application::Plugin::Authentication::Store::delete('username') } qr/delete must be implemented in the/, 'Store dies when delete is called without being overridden in the subclass';

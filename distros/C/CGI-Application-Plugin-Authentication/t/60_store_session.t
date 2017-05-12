#!/usr/bin/perl
use strict;
use warnings;
use lib qw(t);

use CGI::Util;

use Test::More;
eval "use CGI::Application::Plugin::Session";
plan skip_all => "CGI::Application::Plugin::Session required for this test" if $@;
plan tests => 14;

{

    package TestAppStoreSession;

    use base qw(TestAppStore);
    CGI::Application::Plugin::Session->import;  # was loaded conditionally above

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { 'test' => '123' } ],
        STORE  => [ 'Session' ],
        CREDENTIALS => [qw(auth_username auth_password)],
    );

    sub get_store_entries {
        my $class = shift;
        my $cgiapp = shift;
        my $results = shift;

        my $data = {
            username => $cgiapp->session->param('AUTH_USERNAME'),
            login_attempts => $cgiapp->session->param('AUTH_LOGIN_ATTEMPTS'),
        };
        return ($data->{username} || $data->{login_attempts}) ? $data : undef;
    }

    sub maintain_state {
        my $class = shift;
        my $old_cgiapp = shift;
        my $old_results = shift;
        my $new_query = shift;

        $old_cgiapp->session->flush;
        $new_query->param(-name => CGI::Session->name, -value => $old_cgiapp->session->id, -override => 1);
    }

    sub clear_state {
        my $class = shift;
        my $old_cgiapp = shift;
        my $old_results = shift;
        $old_cgiapp->session->clear(['AUTH_USERNAME','AUTH_LOGIN_ATTEMPTS']),
        $old_cgiapp->session->flush;
        $class->SUPER::clear_state(@_);
    }

}


TestAppStoreSession->run_store_tests;



#!perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;

use CGI::Fast socket_path => ":7070";

# override FCGI::Accept method to get none-blocking behaviour
# all we're interested in is having an FCGI::Request object
# that has been instantiated with the ENV hash
no warnings 'redefine';
no warnings 'prototype';
*FCGI::Accept = sub { 1 };

# fake up an ENV containing some CGI specific variables that
# will get passed into FCGI::Request on the instantiation
$ENV{$_} = $_
    for qw(REMOTE_ADDR HTTP_COOKIE PATH_INFO QUERY_STRING);

foreach my $i ( 1 .. 5 ) {

    # first loop will instantiate FCGI::Request object
    # second loop needs an initialiser as ->Accept will
    # return -1 so the call to ->new will return undef
    my $q = CGI::Fast->new;

    # even requests will contain empty ENV
    if ( $i % 2 == 0 ) {
        delete( $ENV{$_} )
            for qw(REMOTE_ADDR HTTP_COOKIE PATH_INFO QUERY_STRING);
    } else {
        $ENV{$_} = $_
            for qw(REMOTE_ADDR HTTP_COOKIE PATH_INFO QUERY_STRING);
    }

    my $cgi_vars = {
        map { $_ => $q->$_ }
        qw/remote_addr raw_cookie path_info query_string/
    };

    if ( $i % 2 == 0 ) {
        cmp_deeply(
            $cgi_vars,
            {
                remote_addr  => ignore(),
                raw_cookie   => '',
                path_info    => '',
                query_string => '',
            },
            'ENV variables not reused from last request'
        );
    } else {
        cmp_deeply(
            $cgi_vars,
            {
                remote_addr  => 'REMOTE_ADDR',
                raw_cookie   => 'HTTP_COOKIE',
                path_info    => 'PATH_INFO',
                query_string => '',
            },
            'ENV variables set from current environment'
        );
    }
}

use Test::More tests => 4;

use strict;
use warnings;

use Dancer::Session::DBI;
use Dancer qw(:syntax :tests);



# ONE
eval {
    set session => 'DBI';
    session->create();
};
like $@, qr{No table selected for session storage}i,
    'Should fail when no settings specified';



# TWO
eval {
    set session => 'DBI';
    set 'session_options' => {
        table => 'table',
        dsn   => 'Invalid',
    };
    session->create();
};
like $@, qr{No valid DSN specified}i,
    'Should fail on invalid DSN';



# THREE
eval {
    set session => 'DBI';
    set 'session_options' => {
        table => 'table',
        dsn   => 'DBI:MyDriver(RaiseError=>1):db=test;port=42',
    };
    session->create();
};
like $@, qr{No user or password specified}i,
    'Should fail with no user or password';



# FOUR
eval {
    set session => 'DBI';
    set 'session_options' => {
        table    => '',
        dbh      => 'Handle',
        user     => 'user',
        password => 'password'
    };
    session->create();
};
like $@, qr{No table selected for session storage}i,
    'Should fail with no table selected';


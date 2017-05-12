#!/usr/bin/perl
use Test::More;
use lib qw(t);
eval "use Authen::Simple";
plan skip_all => "Authen::Simple required for this test" if $@;

plan tests => 11;

use strict;
use warnings;

{
    package TestAppDriverAuthenSimple;

    use base qw(TestAppDriver);

    __PACKAGE__->authen->config(
        DRIVER => [ 'Authen::Simple::Dummy', testuser => 'user1', testpass => '123' ],
        STORE  => 'Store::Dummy',
    );

}

TestAppDriverAuthenSimple->run_authen_tests(
    [ 'authen_username', 'authen_password' ],
    [ 'user1', '123' ],
);


TestAppDriverAuthenSimple->run_authen_failure_tests(
    [ 'authen_username', 'authen_password' ],
    [ 'user1', '1234' ],
);

# Test covering certain coverage cases
TestAppDriverAuthenSimple->run_authen_failure_tests(
    [ 'authen_username', 'authen_password' ],
    [ 0, 'hhhh'],
);


$ENV{CGI_APP_RETURN_ONLY} = 1;

my $params = {
    rm => 'protected',
    authen_username => undef,
    authen_password => '2234'
};

{
    use CGI;
    my $query = CGI->new( $params );
    my $cgiapp = TestAppDriverAuthenSimple->new( QUERY => $query );
    my @drivers = $cgiapp->authen->drivers;
    ok(!defined $drivers[0]->verify_credentials(undef, '2234'), 'impossible case');
}


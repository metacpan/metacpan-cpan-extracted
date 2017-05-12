#!/usr/bin/perl
use Test::More tests => 13;

use strict;
use warnings;
use lib qw(t);

use CGI ();

our %STORE;

{
    package TestAppTimeout;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authentication;

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { user => '123' } ],
        STORE  => [ 'Store::Dummy', \%STORE ],
        LOGIN_SESSION_TIMEOUT => {
            IDLE_FOR => '30',
            EVERY => '30',
            CUSTOM => sub { 0 },
        },
    );

    sub setup {
        my $self = shift;
        $self->start_mode('one');
        $self->run_modes([qw(one two)]);
        $self->authen->protected_runmodes(qw(two));
    }

    sub one {
        my $self = shift;
    }

    sub two {
        my $self = shift;
    }
}

$ENV{CGI_APP_RETURN_ONLY} = 1;

my ($now, $query, $cgiapp, $results);

diag('The following tests have some small time delays');

$query   = CGI->new( { authen_username => 'user', authen_password => '123', rm => 'two' } );
$cgiapp  = TestAppTimeout->new( QUERY => $query );
$results = $cgiapp->run;

ok( $cgiapp->authen->is_authenticated,'successful login' );
is( $cgiapp->authen->username, 'user', 'username set' );
is( $STORE{username}, 'user', 'username set in store' );
$now = time();
ok( $STORE{last_access} <= $now && $STORE{last_access} >= $now - 5, 'last access looks reasonable' );
ok( $STORE{last_login} <= $now && $STORE{last_login} >= $now - 5, 'last login looks reasonable' );

# Sleep so we know if the last_access time is updated
select(undef, undef, undef, 1.1);

$query   = CGI->new( { rm => 'two' } );
$cgiapp  = TestAppTimeout->new( QUERY => $query );
$results = $cgiapp->run;


ok( $STORE{last_access} > $STORE{last_login}, 'last access updated on next request' );

# If we log out, make sure it is not marked as caused by a timeout
ok ($cgiapp->authen->logout, "Logout manually");
ok( !$cgiapp->authen->is_authenticated, 'user logged out' );
ok( !$cgiapp->authen->is_login_timeout, 'logout not caused by timeout' );


{
    package TestAppTimeoutIDLE_FOR;

    use base qw(TestAppTimeout);

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { user => '123' } ],
        STORE  => [ 'Store::Dummy', \%STORE ],
        LOGIN_SESSION_TIMEOUT => {
            IDLE_FOR => '1',
        },
    );
}

# login again
$query   = CGI->new( { authen_username => 'user', authen_password => '123', rm => 'two' } );
$cgiapp  = TestAppTimeout->new( QUERY => $query );
$results = $cgiapp->run;
# Sleep so we have enough idle time
select(undef, undef, undef, 1.1);
$query   = CGI->new( { rm => 'two' } );
$cgiapp  = TestAppTimeoutIDLE_FOR->new( QUERY => $query );
$results = $cgiapp->run;


ok( !$cgiapp->authen->is_authenticated, 'IDLE_FOR idle time exceeded so user logged out' );
ok( $cgiapp->authen->is_login_timeout, 'logout caused by timeout' );


{
    package TestAppTimeoutEVERY;

    use base qw(TestAppTimeout);

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { user => '123' } ],
        STORE  => [ 'Store::Dummy', \%STORE ],
        LOGIN_SESSION_TIMEOUT => {
            EVERY => '1',
        },
    );
}

# login again
$query   = CGI->new( { authen_username => 'user', authen_password => '123', rm => 'two' } );
$cgiapp  = TestAppTimeoutEVERY->new( QUERY => $query );
$results = $cgiapp->run;
# Sleep so we have enough idle time
select(undef, undef, undef, 1.1);
$query   = CGI->new( { rm => 'two' } );
$cgiapp  = TestAppTimeoutEVERY->new( QUERY => $query );
$results = $cgiapp->run;


ok( !$cgiapp->authen->is_authenticated, 'EVERY idle time exceeded so user logged out' );



{
    package TestAppTimeoutCUSTOM;

    use base qw(TestAppTimeout);

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { user => '123' } ],
        STORE  => [ 'Store::Dummy', \%STORE ],
        LOGIN_SESSION_TIMEOUT => {
            CUSTOM => sub { 1 },
        },
    );
}

# login again
$query   = CGI->new( { authen_username => 'user', authen_password => '123', rm => 'two' } );
$cgiapp  = TestAppTimeoutCUSTOM->new( QUERY => $query );
$results = $cgiapp->run;
# no need to sleep here
$query   = CGI->new( { rm => 'two' } );
$cgiapp  = TestAppTimeoutCUSTOM->new( QUERY => $query );
$results = $cgiapp->run;


ok( !$cgiapp->authen->is_authenticated, 'CUSTOM idle time exceeded so user logged out' );


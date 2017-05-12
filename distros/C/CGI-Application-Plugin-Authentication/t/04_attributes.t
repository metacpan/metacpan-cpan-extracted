#!/usr/bin/perl
use Test::More tests => 7;

use lib './t';
use strict;
use warnings;
use CGI ();

{

    package TestAppAttributes;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authentication;

    __PACKAGE__->authen->config(
        DRIVER => [ 'Generic', { user1 => '123' } ],
        STORE  => 'Store::Dummy',
    );

    sub setup {
        my $self = shift;
        $self->start_mode('one');
        $self->run_modes( [qw(one two three four)] );
        $self->authen->protected_runmodes(qw(two));
    }

    sub one { return 'test one return value'; }
    sub two { return 'test two return value'; }
    sub three : RequireAuthentication { return 'test three return value'; }
    sub four : Authen(value) { return 'test four return value'; }
}


$ENV{CGI_APP_RETURN_ONLY} = 1;

{
    # Open runmode
    my $query = CGI->new( { rm => 'one' } );
    my $cgiapp = TestAppAttributes->new( QUERY => $query );
    my $results = $cgiapp->run;

    like($results, qr/test one return value/, 'runmode one is open');
}

{
    # Protected runmode (regular)
    my $query = CGI->new( { rm => 'two' } );
    my $cgiapp = TestAppAttributes->new( QUERY => $query );
    my $results = $cgiapp->run;

    unlike($results, qr/test two return value/, 'runmode two is protected');
}

{
    # Protected runmode (attribute RequireAuthentication)
    my $query = CGI->new( { rm => 'three' } );
    my $cgiapp = TestAppAttributes->new( QUERY => $query );
    my $results = $cgiapp->run;

    unlike($results, qr/test three return value/, 'runmode three is protected');
}

{
    # Protected runmode (attribute Authen)
    my $query = CGI->new( { rm => 'four' } );
    my $cgiapp = TestAppAttributes->new( QUERY => $query );
    my $results = $cgiapp->run;

    unlike($results, qr/test four return value/, 'runmode four is protected');
}

{
    # Successful Login
    my $query = CGI->new( { authen_username => 'user1', authen_password => '123', rm => 'three' } );
    my $cgiapp = TestAppAttributes->new( QUERY => $query );
    my $results = $cgiapp->run;

    ok($cgiapp->authen->is_authenticated,'successful login');
    is( $cgiapp->authen->username, 'user1', 'successful login - username set' );
    like($results, qr/test three return value/, 'runmode three is visible after login');
}

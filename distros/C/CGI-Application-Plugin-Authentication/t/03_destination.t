#!/usr/bin/perl  -T
use Test::More;
use Test::Taint;
use Test::Regression;
use Test::Warn;
use English qw(-no_match_vars);
use strict;
use warnings;

if ($OSNAME eq 'MSWin32') {
    my $msg = 'Not running these tests on windows yet';
    plan skip_all => $msg;
    exit(0);
}

plan tests => 11;

use strict;
use warnings;
taint_checking_ok('taint checking is on');

use CGI ();

my $cap_options =
{
        DRIVER => [ 'Generic', { user1 => '123' } ],
        STORE => ['Cookie', SECRET => "Shhh, don't tell anyone", NAME => 'CAPAUTH_DATA', EXPIRY => '+1y'],
        POST_LOGIN_CALLBACK => \&TestAppAuthenticate::post_login,
};

{

    package TestAppAuthenticate;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authentication;

    sub setup {
        my $self = shift;
        $self->start_mode('one');
        $self->run_modes([qw(one two three)]);
        $self->authen->protected_runmodes(qw(two three));
        $self->authen->config($cap_options);
    }

    sub one {
        my $self = shift;
        return "<html><body>ONE</body></html>";
    }

    sub two {
        my $self = shift;
        return "<html><body>TWO</body></html>";
    }

    sub three {
        my $self = shift;
        return "<html><body>THREE</body></html>";
    }

    sub post_login {
      my $self = shift;

      my $count=$self->param('post_login')||0;
      $self->param('post_login' => $count + 1 );
    }

}

$ENV{CGI_APP_RETURN_ONLY} = 1;

# successful login
subtest 'straightforward use of destination parameter' => sub {
        plan tests => 5;
        my $query = CGI->new( { authen_username => 'user1', rm => 'two', authen_password=>'123', destination=>'http://news.bbc.co.uk' } );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/redirect", "redirection");

        ok($cgiapp->authen->is_authenticated,'login success');
        is( $cgiapp->authen->username, 'user1', "login success - username set" );
        is( $cgiapp->authen->login_attempts, 0, "successful login - failed login count" );
        is( $cgiapp->param('post_login'),1,'successful login - POST_LOGIN_CALLBACK executed' );
};

subtest 'redirection including CRLF' => sub {
        plan tests => 5;
        my $query = CGI->new( { authen_username => 'user1', rm => 'two', authen_password=>'123', destination=>'http://news.bbc.co.uk\r\nLocation: blah' } );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/crlf", "crlf");

        ok($cgiapp->authen->is_authenticated,'login success');
        is( $cgiapp->authen->username, 'user1', "login success - username set" );
        is( $cgiapp->authen->login_attempts, 0, "successful login - failed login count" );
        is( $cgiapp->param('post_login'),1,'successful login - POST_LOGIN_CALLBACK executed' );
};

subtest 'redirection with constraining taint check' => sub {
        plan tests => 5;
        local $cap_options->{DETAINT_URL_REGEXP} = '^(http\:\/\/www\.perl.org\/[\w\_\%\?\&\;\-\/\@\.\+\$\=\#\:\!\*\"\'\(\)\,]+)$';
        my $query = CGI->new( { authen_username => 'user1', rm => 'two', authen_password=>'123', destination=>'http://news.bbc.co.uk' } );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/restricted", "restricted");

        ok($cgiapp->authen->is_authenticated,'login success');
        is( $cgiapp->authen->username, 'user1', "login success - username set" );
        is( $cgiapp->authen->login_attempts, 0, "successful login - failed login count" );
        is( $cgiapp->param('post_login'),1,'successful login - POST_LOGIN_CALLBACK executed' );
};

subtest 'user name failing taint check' => sub {
        plan tests => 5;
        local $cap_options->{DETAINT_USERNAME_REGEXP} = '^([A-Z]+)$';
        my $query = CGI->new( { authen_username => 'user1', rm => 'two', destination=>'http://news.bbc.co.uk' } );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/username", "username");

        ok(!$cgiapp->authen->is_authenticated,'login failure');
        is( $cgiapp->authen->username, undef, "login failure - username not set" );
        is( $cgiapp->authen->login_attempts, 1, "failed login - failed login count" );
        is( $cgiapp->param('post_login'),1,'failed login - POST_LOGIN_CALLBACK executed' );
};

subtest 'user name failing taint check - basic' => sub {
        plan tests => 5;
        local $cap_options->{LOGIN_FORM}->{DISPLAY_CLASS} = 'Basic';
        local $cap_options->{DETAINT_USERNAME_REGEXP} = '^([A-Z]+)$';
        my $query = CGI->new( { authen_username => 'user1', rm => 'two', destination=>'http://news.bbc.co.uk' } );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/username-basic", "username basic");

        ok(!$cgiapp->authen->is_authenticated,'login failure');
        is( $cgiapp->authen->username, undef, "login failure - username not set" );
        is( $cgiapp->authen->login_attempts, 1, "failed login - failed login count" );
        is( $cgiapp->param('post_login'),1,'failed login - POST_LOGIN_CALLBACK executed' );
};

subtest 'POST_LOGIN_URL usage' => sub {
        plan tests => 5;
        local $cap_options->{POST_LOGIN_URL} = 'http://www.perl.org';
        my $query = CGI->new( { authen_username => 'user1', rm => 'two', authen_password=>'123', destination=>'http://news.bbc.co.uk' } );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/loginurl", "loginurl");

        ok($cgiapp->authen->is_authenticated,'login success');
        is( $cgiapp->authen->username, 'user1', "login success - username set" );
        is( $cgiapp->authen->login_attempts, 0, "successful login - failed login count" );
        is( $cgiapp->param('post_login'),1,'successful login - POST_LOGIN_CALLBACK executed' );
};

subtest 'POST_LOGIN_RUNMODE usage' => sub {
        plan tests => 6;
        local $cap_options->{POST_LOGIN_RUNMODE} = 'three';
        local $cap_options->{POST_LOGIN_URL} = 'http://www.perl.org';
        my $query = CGI->new( { authen_username => 'user1', rm => 'two', authen_password=>'123', destination=>'http://news.bbc.co.uk' } );

        my $cgiapp;
        warning_is {$cgiapp = TestAppAuthenticate->new( QUERY => $query );}
            "authen config warning:  parameter POST_LOGIN_URL ignored since we already have POST_LOGIN_RUNMODE",
            "checking generated warning";
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/runmode", "runmode");

        ok($cgiapp->authen->is_authenticated,'login success');
        is( $cgiapp->authen->username, 'user1', "login success - username set" );
        is( $cgiapp->authen->login_attempts, 0, "successful login - failed login count" );
        is( $cgiapp->param('post_login'),1,'successful login - POST_LOGIN_CALLBACK executed' );
        
};

subtest 'LOGOUT usage' => sub {
        plan tests => 2;
        local $cap_options->{POST_LOGIN_RUNMODE} = 'three';
        my $query = CGI->new( { authen_username => 'user1', rm => 'two', authen_password=>'123', authen_logout=>1, destination=>'http://news.bbc.co.uk' } );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/logout", "logout");
        ok(!$cgiapp->authen->is_authenticated,'logout success');
        
};

subtest 'Redirection failure' => sub {
        plan tests => 1;
        local $ENV{PATH_INFO} = '!!!!';
        local $cap_options->{DETAINT_URL_REGEXP} = '^(\w+)$';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/redirection_failure", "redirection_failure");

};

subtest 'Redirection failure [Basic]' => sub {
        plan tests => 1;
        local $ENV{PATH_INFO} = '!!!!';
        local $cap_options->{DETAINT_URL_REGEXP} = '^(\w+)$';
        local $cap_options->{LOGIN_FORM}->{DISPLAY_CLASS} = 'Basic';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/redirection_failure_basic", "redirection_failure [Basic]");

};

sub make_output_timeless {
        my $output = shift;
        $output =~ s/^(Set-Cookie: CAPAUTH_DATA=\w+\%3D(?:\%3D)?\; path=\/\; expires=\w{3},\s\d{2}\-\w{3}\-\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Set-Cookie: CAPAUTH_DATA=; path=\/; expires=;$2/m;
        $output =~ s/^(Expires:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Expires$2/m;
        $output =~ s/^(Date:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Date$2/m;
        #$output =~ s/\r//g;
        return $output;
}



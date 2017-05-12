#!/usr/bin/perl -wT
use Test::More;
use Test::Taint;
use Test::Regression;
use English qw(-no_match_vars);
use lib qw(t);


BEGIN {
    use Test::More;
    eval {require CGI::Application::Plugin::ActionDispatch;};
    if ($@) {
        my $msg = 'CGI::Application::Plugin::ActionDispatch required';
        plan skip_all => $msg;
    }
    if ($OSNAME eq 'MSWin32') {
        my $msg = 'Not running these tests on windows yet';
        plan skip_all => $msg;
    }
    plan tests => 4;
}

use strict;
use warnings;
use CGI ();

taint_checking_ok('taint checking is on');

my $cap_options =
{
        DRIVER => [ 'Generic', { user1 => '123' } ],
        STORE => ['Cookie', SECRET => "Shhh, don't tell anyone", NAME => 'CAPAUTH_DATA', EXPIRY => '+1y'],
        POST_LOGIN_CALLBACK => \&TestAppAuthenticate::post_login,
};

{

    package TestAppAuthenticate;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::ActionDispatch;
    use CGI::Application::Plugin::Authentication;

    sub setup {
        my $self = shift;
        $self->authen->protected_runmodes(qw(protected));
        $self->authen->config($cap_options);
    }
    
    sub unprotected : Default {
        return "This is public";
    }

    sub protected : Path('private') {
        return "This is private";
    }
    
    sub post_login {
      my $self = shift;

      my $count=$self->param('post_login')||0;
      $self->param('post_login' => $count + 1 );
    }
}

$ENV{CGI_APP_RETURN_ONLY} = 1;

# front page
subtest 'front page' => sub {
        plan tests => 2;
        my $query = CGI->new();

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/frontpage", "frontpage");

        ok(!$cgiapp->authen->is_authenticated,'not authenticated');
};

# login intercepted
subtest 'interception' => sub {
        plan tests => 3;
        local $ENV{PATH_INFO} = '/private';
        my $query = CGI->new();

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/login", "login");

        ok(!$cgiapp->authen->is_authenticated,'not authenticated');
        ok( !defined($cgiapp->param('post_login')),'unsuccessful login' );
};

# successful login
subtest 'successful login' => sub {
        plan tests => 5;
        local $ENV{PATH_INFO} = '/private';
        my $query = CGI->new( { authen_username => 'user1', authen_password=>'123'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/success", "success");

        ok($cgiapp->authen->is_authenticated,'login success');
        is( $cgiapp->authen->username, 'user1', "login success - username set" );
        is( $cgiapp->authen->login_attempts, 0, "successful login - failed login count" );
        is( $cgiapp->param('post_login'),1,'successful login - POST_LOGIN_CALLBACK executed' );
};

sub make_output_timeless {
        my $output = shift;
        $output =~ s/^(Set-Cookie: CAPAUTH_DATA=\w+\%3D\%3D\; path=\/\; expires=\w{3},\s\d{2}\-\w{3}\-\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Set-Cookie: CAPAUTH_DATA=; path=\/; expires=;$2/m;
        $output =~ s/^(Expires:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Expires$2/m;
        $output =~ s/^(Date:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Date$2/m;
        #$output =~ s/\r//g;
        return $output;
}

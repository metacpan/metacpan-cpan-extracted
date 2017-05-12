#!/usr/bin/perl -wT
use Test::More;
use Test::Taint;
use Test::Regression;
use English qw(-no_match_vars);
use lib qw(t);


BEGIN {
    $ENV{CGI_APP_RETURN_ONLY} = 1;
    $ENV{CAP_DEVPOPUP_EXEC} = 1;

    use Test::More;
    eval {require CGI::Application::Plugin::DevPopup};
    if ($@) {
        my $msg = 'CGI::Application::Plugin::DevPopup required';
        plan skip_all => $msg;
    }
    if ($OSNAME eq 'MSWin32') {
        my $msg = 'Not running these tests on windows yet';
        plan skip_all => $msg;
    }
    if ($CGI::Application::Plugin::DevPopup::VERSION < 1.05) {
        my $msg = 'There are some odd test failures that MAY be due to old versions of DevPopup';
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
	POST_LOGIN_RUNMODE=>'protected',
};

{

    package TestAppAuthenticate;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::Authentication;

    sub setup {
        my $self = shift;
        $self->authen->protected_runmodes(qw(protected));
        $self->authen->config($cap_options);
	$self->run_modes(
		protected=>'protected',
		unprotected=>'unprotected',
	);
	$self->start_mode('unprotected');
    }
    
    sub unprotected {
        return "This is public";
    }

    sub protected {
        return "This is private";
    }
    
}

# front page
subtest 'front page' => sub {
        plan tests => 2;
        my $query = CGI->new();

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/frontpage-dev", "frontpage");

        ok(!$cgiapp->authen->is_authenticated,'not authenticated');
};

# login intercepted
subtest 'interception' => sub {
        plan tests => 2;
        local $ENV{PATH_INFO} = '/private';
        my $query = CGI->new();

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/login-dev", "login");

        ok(!$cgiapp->authen->is_authenticated,'not authenticated');
};

# successful login
subtest 'successful login' => sub {
        plan tests => 4;
        local $ENV{PATH_INFO} = '/private';
        my $query = CGI->new( { authen_username => 'user1', authen_password=>'123'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/success-dev", "success");

        ok($cgiapp->authen->is_authenticated,'login success');
        is( $cgiapp->authen->username, 'user1', "login success - username set" );
        is( $cgiapp->authen->login_attempts, 0, "successful login - failed login count" );
};

sub make_output_timeless {
        my $output = shift;
        $output =~ s/^(Set-Cookie: CAPAUTH_DATA=\w+\%3D\%3D\; path=\/\; expires=\w{3},\s\d{2}\-\w{3}\-\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Set-Cookie: CAPAUTH_DATA=; path=\/; expires=;$2/m;
        $output =~ s/^(Expires:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Expires$2/m;
        $output =~ s/^(Date:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Date$2/m;
        #$output =~ s/\r//g;
        return $output;
}



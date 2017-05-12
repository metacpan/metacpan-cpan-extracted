#!/usr/bin/perl  -T
use Test::More;
use Test::Taint;
use Test::Regression;
use Test::NoWarnings;
use Test::Warn;
use Test::Without::Module qw(Color::Calc);
use English qw(-no_match_vars);

if ($OSNAME eq 'MSWin32') {
    my $msg = 'Not running these tests on windows yet';
    plan skip_all => $msg;
    exit(0);
}

plan tests => 4;

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


subtest 'Base color' => sub {
        plan tests => 2;
        local $cap_options->{LOGIN_FORM}->{BASE_COLOUR} = 'purple';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        my $output;
        warning_is {$output = $cgiapp->run;}
            "Color::Calc is required when specifying a custom BASE_COLOUR, and leaving LIGHTER_COLOUR, LIGHT_COLOUR, DARK_COLOUR or DARKER_COLOUR blank or when providing percentage based colour",
            "checking generated warning";
        ok_regression(sub {make_output_timeless($output)}, "t/out/missing_color", "Missing color");

};


subtest 'No Base color' => sub {
        plan tests => 1;
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/missing_color", "Missing color");

};

sub make_output_timeless {
        my $output = shift;
        $output =~ s/^(Set-Cookie: CAPAUTH_DATA=\w+\%3D\%3D\; path=\/\; expires=\w{3},\s\d{2}\-\w{3}\-\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Set-Cookie: CAPAUTH_DATA=; path=\/; expires=;$2/m;
        $output =~ s/^(Expires:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Expires$2/m;
        $output =~ s/^(Date:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Date$2/m;
        #$output =~ s/\r//g;
        return $output;
}



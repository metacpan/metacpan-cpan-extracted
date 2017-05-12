#!/usr/bin/perl  
# taint chcking seems to break Devel::Cover
use Test::More;
use Test::Regression;
use Test::Warn;
use English qw(-no_match_vars);

BEGIN {
    use Test::More;
    eval {require Color::Calc;};
    if ($@) {
        my $msg = 'Color::Calc required';
	diag $msg;
        plan skip_all => $msg;
    }
    if ($OSNAME eq 'MSWin32') {
        my $msg = 'Not running these tests on windows yet';
        plan skip_all => $msg;
    }
    plan tests => 7;

}

use strict;
use warnings;

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

subtest 'Various other pemutations' => sub {
        plan tests => 1;
        undef local $cap_options->{LOGIN_FORM}->{COMMENT};
        local $cap_options->{LOGIN_FORM}->{FOCUS_FORM_ONLOAD} = 1;
        local $cap_options->{LOGIN_FORM}->{REMEMBERUSER_OPTION} = 0;
        local $cap_options->{LOGIN_FORM}->{REGISTER_URL} = '/register';
        local $cap_options->{LOGIN_FORM}->{FORGOTPASSWORD_URL} = '/forgot';
        local $cap_options->{LOGIN_FORM}->{GREY_COLOUR} = 'purple';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/other_permutations", "Other permutations");

};

subtest 'Percentage' => sub {
        plan tests => 1;
        local $cap_options->{LOGIN_FORM}->{LIGHT_COLOUR} = '20%';
        local $cap_options->{LOGIN_FORM}->{LIGHTER_COLOUR} = '10%';
        local $cap_options->{LOGIN_FORM}->{DARK_COLOUR} = '80%';
        local $cap_options->{LOGIN_FORM}->{DARKER_COLOUR} = '90%';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/percentage", "Percentage");

};

subtest 'Names of colours' => sub {
        plan tests => 1;
        local $cap_options->{LOGIN_FORM}->{LIGHT_COLOUR} = '110%';
        local $cap_options->{LOGIN_FORM}->{LIGHTER_COLOUR} = 'red';
        local $cap_options->{LOGIN_FORM}->{DARK_COLOUR} = 'green';
        local $cap_options->{LOGIN_FORM}->{DARKER_COLOUR} = 'blue';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/names_of_colours", "Names of colours");

};



subtest 'Names of colours II' => sub {
        plan tests => 1;
        local $cap_options->{LOGIN_FORM}->{LIGHT_COLOUR} = 'orange';
        local $cap_options->{LOGIN_FORM}->{LIGHTER_COLOUR} = 'red';
        local $cap_options->{LOGIN_FORM}->{DARK_COLOUR} = '110%';
        local $cap_options->{LOGIN_FORM}->{DARKER_COLOUR} = 'blue';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/names_of_colours_2", "Names of colours");

};



subtest 'Names of colours III' => sub {
        plan tests => 1;
        local $cap_options->{LOGIN_FORM}->{LIGHT_COLOUR} = 'orange';
        local $cap_options->{LOGIN_FORM}->{LIGHTER_COLOUR} = 'red';
        local $cap_options->{LOGIN_FORM}->{DARK_COLOUR} = 'purple';
        local $cap_options->{LOGIN_FORM}->{DARKER_COLOUR} = 'blue';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/names_of_colours_3", "Names of colours");

};



subtest 'grey' => sub {
        plan tests => 1;
        local $cap_options->{LOGIN_FORM}->{LIGHT_COLOUR} = 'orange';
        local $cap_options->{LOGIN_FORM}->{LIGHTER_COLOUR} = '15%';
        local $cap_options->{LOGIN_FORM}->{DARK_COLOUR} = 'purple';
        local $cap_options->{LOGIN_FORM}->{DARKER_COLOUR} = 'blue';
        local $cap_options->{LOGIN_FORM}->{GREY_COLOUR} = 'blue';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/grey", "grey");

};


subtest 'grey II' => sub {
        plan tests => 1;
        local $cap_options->{LOGIN_FORM}->{LIGHT_COLOUR} = 'orange';
        local $cap_options->{LOGIN_FORM}->{LIGHTER_COLOUR} = '15%';
        local $cap_options->{LOGIN_FORM}->{DARK_COLOUR} = 'purple';
        local $cap_options->{LOGIN_FORM}->{DARKER_COLOUR} = 'blue';
        local $cap_options->{LOGIN_FORM}->{GREY_COLOUR} = '0';
        my $query = CGI->new( { rm => 'two'} );

        my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
        ok_regression(sub {make_output_timeless($cgiapp->run)}, "t/out/grey2", "grey");

};


sub make_output_timeless {
        my $output = shift;
        $output =~ s/^(Set-Cookie: CAPAUTH_DATA=\w+\%3D\%3D\; path=\/\; expires=\w{3},\s\d{2}\-\w{3}\-\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Set-Cookie: CAPAUTH_DATA=; path=\/; expires=;$2/m;
        $output =~ s/^(Expires:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Expires$2/m;
        $output =~ s/^(Date:\s\w{3},\s\d{2}\s\w{3}\s\d{4}\s\d{2}:\d{2}:\d{2}\s\w{3})([\r\n\s]*)$/Date$2/m;
        #$output =~ s/\r//g;
        return $output;
}



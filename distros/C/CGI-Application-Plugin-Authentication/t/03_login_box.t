#!/usr/bin/perl  -T
use Test::More;
use Test::Taint;
use Test::Regression;
use English qw(-no_match_vars);

if ($OSNAME eq 'MSWin32') {
    my $msg = 'Not running these tests on windows yet';
    plan skip_all => $msg;
    exit(0);
}
plan tests => 7;

use strict;
use warnings;

use CGI ();
taint_checking_ok('taint checking is on');
$ENV{CGI_APP_RETURN_ONLY} = 1;

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
        $self->run_modes([qw(one two)]);
        $self->authen->protected_runmodes(qw(two));
        $self->authen->config($cap_options);
    }

    sub one {
        my $self = shift;
    }

    sub two {
        my $self = shift;
    }

    sub post_login {
      my $self = shift;

      my $count=$self->param('post_login')||0;
      $self->param('post_login' => $count + 1 );
    }

}

test_auth();
test_auth('cosmetic', {
        TITLE=>'Aanmelden',
        USERNAME_LABEL=>'Gebruikersnaam',
        PASSWORD_LABEL=>'Wachtwoord',
        SUBMIT_LABEL=>'Aanmelden',
        COMMENT=>'Vul uw gebruikersnaam en wachtwoord in de velden hieronder.',
        REMEMBERUSER_LABEL=>'Onthouden Gebruikersnaam',
        INVALIDPASSWORD_MESSAGE=>'Ongeldige gebruikersnaam of wachtwoord <br /> (login poging% d)',
        INCLUDE_STYLESHEET=>0
});
test_auth('red', {
        BASE_COLOUR=>'#884454',
        LIGHT_COLOUR=>'49%',
        LIGHTER_COLOUR=>'74%',
        DARK_COLOUR=>'29%',
        DARKER_COLOUR=>'59%'
}, 1);
test_auth('green', {
        BASE_COLOUR=>'#2cf816'
}, 1);
test_auth('grey_extra', {
        BASE_COLOUR=>'#445588',
}, 1);
test_auth('grey_extra2', {
        GREY_COLOUR=>'#334488',
        BASE_COLOUR=>'#445588',
}, 1);



sub test_auth {
    my $test_name = shift || "default";
    my $login_form = shift;
    my $color_calc_required = shift;
    if (defined $color_calc_required) {
        eval "use Color::Calc";
        if ($@) {
                diag "Color::Calc required for this sub test";
                pass($test_name);
                return;
        }
    }
    subtest $test_name => sub {
       plan tests => 11;
       local $cap_options->{LOGIN_FORM} = $login_form if $login_form;

       # Missing Credentials
       my $param = { authen_username => 'user1', rm => 'two' };
       taint_deeply($param);
       my $query = CGI->new( $param);

       my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

       my $results = $cgiapp->run;

       ok(!$cgiapp->authen->is_authenticated,"$test_name - login failure");
       is( $cgiapp->authen->username, undef, "$test_name - username not set" );
       is( $cgiapp->param('post_login'),1,"$test_name - POST_LOGIN_CALLBACK executed" );
       is( $cgiapp->authen->_detaint_destination, '', "$test_name - _detaint_destination");
       untainted_ok($cgiapp->authen->_detaint_destination, "$test_name - _detaint_destination untainted");
       # hash order is random
       ok($cgiapp->authen->_detaint_selfurl eq 'http://localhost?authen_username=user1;rm=two' ||
          $cgiapp->authen->_detaint_selfurl eq 'http://localhost?rm=two;authen_username=user1',
          "$test_name - _detaint_selfurl");
       untainted_ok($cgiapp->authen->_detaint_selfurl, "$test_name - _detaint_selfurl untainted");
       is( $cgiapp->authen->_detaint_url, '', "$test_name - _detaint_url");
       untainted_ok($cgiapp->authen->_detaint_url, "$test_name - _detaint_url untainted");
       TODO: {
          local $TODO = 'Checking output against past runs is incompatible with
          random hash order.  URLs with params are generated from the keys of a
          hash and thus each run can have some minor differences in URLs.';
          ok_regression(sub {$cgiapp->authen->login_box}, "t/out/$test_name", "$test_name - verify login box");
       }
       untainted_ok($cgiapp->authen->login_box, "$test_name - check login box taint");
    }
}

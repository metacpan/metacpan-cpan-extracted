#!/usr/bin/perl  -T
use Test::More;
use Test::Taint;
use Test::Exception;
use Test::Regression;
use English qw(-no_match_vars);
use lib qw(t);

if ($OSNAME eq 'MSWin32') {
    my $msg = 'Not running these tests on windows yet';
    plan skip_all => $msg;
}

plan tests => 46;
srand(0);

use strict;
use warnings;
taint_checking_ok('taint checking is on');

use CGI ();

my $cap_options = {
    STORE => [
        'Cookie',
        SECRET => "Shhh, don't tell anyone",
        NAME   => 'CAPAUTH_DATA',
        EXPIRY => '+1y'
    ],
};

{

    package TestAppAuthenticate;

    use base qw(CGI::Application);
    use CGI::Application::Plugin::Authentication;

    sub setup {
        my $self = shift;
        $self->start_mode('one');
        $self->run_modes( [qw(one two three)] );
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

        my $count = $self->param('post_login') || 0;
        $self->param( 'post_login' => $count + 1 );
    }

}

$ENV{CGI_APP_RETURN_ONLY} = 1;

# Test 'find_options' function and what happens when we don't define 'verify_credentials'
{
    local $cap_options->{DRIVER} = [
        'Silly',
        option1 => 'Tom',
        option2 => 'Dick',
        option3 => 'Harry'
    ];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );

    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    my @drivers = $cgiapp->authen->drivers;
    ok( scalar(@drivers) == 1, 'We should have just one driver' );

    ok( $drivers[0]->find_option( 'option1', 'Tom' ),   'Tom' );
    ok( $drivers[0]->find_option( 'option2', 'Dick' ),  'Dick' );
    ok( $drivers[0]->find_option( 'option3', 'Harry' ), 'Harry' );
    throws_ok { $cgiapp->run }
      qr/verify_credentials must be implemented in the subclass/,
      'undefined function caught okay';
};

# Test what happens when we have no options.
{
    local $cap_options->{DRIVER} = [ 'Silly', ];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );

    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    ok( !exists $cgiapp->authen->{drivers}, 'nothing cached yet' );
    my @drivers = $cgiapp->authen->drivers;
    ok( scalar(@drivers) == 1, 'We should have just one driver' );
    ok( scalar( @{ $cgiapp->authen->{drivers} } ) == 1, 'cached now' );

    # test caching
    my @drivers1 = $cgiapp->authen->drivers;
    ok( scalar(@drivers1) == 1, 'We should have just one driver' );
    ok( $drivers[0] == $drivers1[0], 'test caching' );

    ok( !defined( $drivers[0]->find_option( 'option1', 'Tom' ) ),   'Tom' );
    ok( !defined( $drivers[0]->find_option( 'option2', 'Dick' ) ),  'Dick' );
    ok( !defined( $drivers[0]->find_option( 'option3', 'Harry' ) ), 'Harry' );
};

# Test what happens when no driver is defined
{
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );

    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    my @drivers = $cgiapp->authen->drivers;
    ok( scalar(@drivers) == 1, 'We should have just one driver' );
    isa_ok(
        $drivers[0],
        'CGI::Application::Plugin::Authentication::Driver::Dummy',
        'Dummy is the default driver'
    );
};

# Test what happens when a non-existent driver is called
{
    local $cap_options->{DRIVER} = ['Blah'];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );

    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
    throws_ok { $cgiapp->authen->drivers } qr/Driver Blah can not be found/,
      'Non existent driver';
};

# Test what happens when a driver constructor dies
{
    local $cap_options->{DRIVER} = ['Die'];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );

    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );
    throws_ok { $cgiapp->authen->drivers }
qr/Could not create new CGI::Application::Plugin::Authentication::Driver::Die object/,
      'Suicidal driver';
};

# Start playing with filter
{
   
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );
    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    ok( !exists $cgiapp->authen->{drivers}, 'nothing cached yet' );
    my @drivers = $cgiapp->authen->drivers;
    ok( scalar(@drivers) == 1, 'We should have just one driver' );
    ok( scalar( @{ $cgiapp->authen->{drivers} } ) == 1, 'cached now' );

    my $driver = ($cgiapp->authen->drivers)[0];
    is($driver->filter('crypt_blah:password', 'hello123', 'UDI'), "UDAdLpAU1oHWU", "crypt - salt=UDI");
    is($driver->filter('crypt_blah:password', 'hello123', 'JJJ'), "JJfyQYJkUrAE6", "crypt - salt=JJJ");
    is($driver->filter('crypt_blah:password', 'hello123'), "8jtQ9rloNVKU.", "crypt - no salt");
    is($driver->filter('crypt_blah:password', 'hello123', ''), "4rJy6RLB765G6", "crypt - bland salt");
    throws_ok { $driver->filter('nonsense:crypt_blah:password', 'hello123', '') }
         qr/No filters found for 'nonsense'/, "undefined filter";
    throws_ok { $driver->filter('md5_blah:crypt_blah:password', 'hello123', '') }
         qr/Unknown MD5 format blah/, "Unknown MD5 parameter";
    throws_ok { $driver->filter('sha1_blah:crypt_blah:password', 'hello123', '') }
         qr/Unknown SHA1 format blah/, "Unknown SHA1 parameter";
};

# Nonsense filter
{
    local $cap_options->{DRIVER} = [
        'Dummy',
        FILTERS=>{nonsense=>'not a suboutine'}
    ];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );
    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    ok( !exists $cgiapp->authen->{drivers}, 'nothing cached yet' );
    my @drivers = $cgiapp->authen->drivers;
    ok( scalar(@drivers) == 1, 'We should have just one driver' );
    ok( scalar( @{ $cgiapp->authen->{drivers} } ) == 1, 'cached now' );

    my $driver = ($cgiapp->authen->drivers)[0];
    throws_ok { $driver->filter('nonsense1_blah:crypt_blah:password', 'hello123', '') }
         qr/No filter found for 'nonsense1'/, "undefined filter";
    throws_ok { $driver->filter('nonsense:crypt_blah:password', 'hello123', '') }
         qr/the 'nonsense' filter listed in FILTERS must be a subroutine reference/, "undefined filter";
};

# FILTERS option not a hashref
{
    local $cap_options->{DRIVER} = [
        'Dummy',
        FILTERS=>'not a hashref'
    ];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );
    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    ok( !exists $cgiapp->authen->{drivers}, 'nothing cached yet' );
    my @drivers = $cgiapp->authen->drivers;
    ok( scalar(@drivers) == 1, 'We should have just one driver' );
    ok( scalar( @{ $cgiapp->authen->{drivers} } ) == 1, 'cached now' );

    my $driver = ($cgiapp->authen->drivers)[0];
    throws_ok { $driver->filter('nonsense_blah:crypt_blah:password', 'hello123', '') }
         qr/the FILTERS configuration option must be a hashref/, "undefined filter";
};

# FILTERS option not a hashref
{
    local $cap_options->{DRIVER} = [
        'Dummy',
        FILTERS=>{nonsense=>\&obfuscate},
    ];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );
    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    ok( !exists $cgiapp->authen->{drivers}, 'nothing cached yet' );
    my @drivers = $cgiapp->authen->drivers;
    ok( scalar(@drivers) == 1, 'We should have just one driver' );
    ok( scalar( @{ $cgiapp->authen->{drivers} } ) == 1, 'cached now' );

    my $driver = ($cgiapp->authen->drivers)[0];
    is($driver->filter('nonsense:password', 'hello123', ''), "|hello123|G", "custom filter");
};

# Generic driver
{
    local $cap_options->{DRIVER} = [
        'Generic', 'Use me if you can'
    ];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );

    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    throws_ok { $cgiapp->run }
      qr/Unknown options for Generic Driver/,
      'Unknown options for Generic Driver';
};

# DBI driver
{
    local $cap_options->{DRIVER} = [
        'DBI', 'Use me if you can'
    ];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );

    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    throws_ok { $cgiapp->run }
      qr/The DBI driver requires a hash of options/,
      'The DBI driver requires a hash of options';
};

# DBI driver (no dbh)
{
    local $cap_options->{DRIVER} = [
        'DBI',
    ];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );

    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    throws_ok { $cgiapp->run }
      qr/No DBH handle passed to the DBI Driver, and no dbh\(\) method detected/,
      'No DBH';
};

# Generic driver where first credential is undefined
{
    local $cap_options->{DRIVER} = [
        'Generic',
	{user=>'123',},
    ];
    my $query = CGI->new(
        {
            authen_username => undef,
            rm              => 'two',
            authen_password => '123',
            destination     => 'http://news.bbc.co.uk'
        }
    );

    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    $cgiapp->run;
    ok(!$cgiapp->authen->is_authenticated, "undefined username");
    my @drivers = $cgiapp->authen->drivers;
    ok(!defined($drivers[0]->verify_credentials(undef, 'blah')));
};

sub obfuscate {
    my $param = shift || "G";
    my $value = shift;
    return "|$value|$param";
}




#!/usr/bin/perl  -T
use Test::More;
use Test::Taint;
use Test::Exception;
use lib qw(t);
use Test::Without::Module qw(Digest::MD5);
use Test::Without::Module qw(Digest::SHA);
use English qw(-no_match_vars);

if ($OSNAME eq 'MSWin32') {
    my $msg = 'Not running these tests on windows yet';
    plan skip_all => $msg;
}
plan tests => 11;
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
    throws_ok { $driver->filter('md5:crypt_blah:password', 'hello123', '') }
         qr/Digest::MD5 is required to check MD5 passwords/, "Digest::MD5 not present";
    throws_ok { $driver->filter('sha1:crypt_blah:password', 'hello123', '') }
         qr/Digest::SHA is required to check SHA1 passwords/, "Digest::SHA not present";
};


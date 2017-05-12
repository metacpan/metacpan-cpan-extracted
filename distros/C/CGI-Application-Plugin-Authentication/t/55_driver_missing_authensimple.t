#!/usr/bin/perl  
use Test::More;
use Test::Exception;
use lib qw(t);
use Test::Without::Module qw(Authen::Simple::Adapter);

plan tests => 4;
srand(0);

use strict;
use warnings;

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

# Authen::Simple
{
    local $cap_options->{DRIVER} = [ 'Authen::Simple::Dummy', testuser => 'user1', testpass => '123' ];
    my $query = CGI->new(
        {
            authen_username => 'user1',
            rm              => 'two',
            authen_password => '123',
        }
    );
    my $cgiapp = TestAppAuthenticate->new( QUERY => $query );

    ok( !exists $cgiapp->authen->{drivers}, 'nothing cached yet' );
    my @drivers = $cgiapp->authen->drivers;
    ok( scalar(@drivers) == 1, 'We should have just one driver' );
    ok( scalar( @{ $cgiapp->authen->{drivers} } ) == 1, 'cached now' );
    throws_ok {$cgiapp->run;} qr/Error executing class callback in prerun stage: The Authen::Simple::Dummy module is not installed/, "missing Authen::Simple";

}

package TestApp;

use warnings;
use MockCrowdApp;

use Catalyst qw/
    Authentication
/;

my $crowd_port = $MockCrowdApp::crowd_server->port;

__PACKAGE__->config(
    'Plugin::Authentication' => {
        use_session => 1,
        default => {
            credential => {
                class => 'Password',
                password_type => 'none',
            },
            store => {
                class => 'Crowd',
                find_user_url => "http://localhost:$crowd_port",
            }
        }
    }
);

__PACKAGE__->setup;

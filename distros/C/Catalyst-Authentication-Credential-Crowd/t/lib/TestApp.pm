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
                class => 'Crowd',
                authen_url => "http://localhost:$crowd_port",
            },
            store => {
                class => 'Null',
            }
        }
    }
);

__PACKAGE__->setup;

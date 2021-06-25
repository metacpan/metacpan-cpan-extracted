package MyApp::Bot;

use strict;
use warnings;

use MyApp::Service::Chat;
use MyApp::Service::Auth;

use Beekeeper::Client;
use Beekeeper::Config;

sub new {
    my ($class, %args) = @_;

    my $self = {
        username => $args{'username'},
    };

    my $config = Beekeeper::Config->read_config_file('client.config.json');

    # Force a new connection
    local $Beekeeper::Client::singleton;

    # Connect to bus 'frontend', wich will forward requests to 'backend'
    $self->{client} = Beekeeper::Client->instance( 
        bus_role   => "frontend",
        forward_to => "backend",
        %$config,
    );

    $self->{chat} = MyApp::Service::Chat->new;
    $self->{auth} = MyApp::Service::Auth->new;

    $self->{chat}->receive_messages(
        callback => $args{'on_message'},
    );

    $self->{auth}->login(
        username => $self->{username},
        password => '123456',
    );

    bless $self, $class;
    return $self;
}

sub username {
    my $self = shift;

    $self->{username};
}

sub talk {
    my ($self, %args) = @_;

    local $Beekeeper::Client::singleton = $self->{client};

    $self->{client}->fire_remote(
        method  => 'myapp.chat.pmessage',
        params  => {
            to_user => $args{'to_user'},
            message => $args{'message'},
        },
    );
}

1;

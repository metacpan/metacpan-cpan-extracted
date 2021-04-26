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

    # Choose a random frontend
    my $frontend_configs = Beekeeper::Config->get_cluster_config( cluster => 'frontend' );
    my $frontend = $frontend_configs->[rand @$frontend_configs];
    my $bus_id = $frontend->{'bus-id'};

    # Force a new connection
    local $Beekeeper::Client::singleton;

    $self->{client} = Beekeeper::Client->instance( 
        bus_id     => $bus_id,   # 'frontend-A' 
        forward_to => 'backend',
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

    $self->{client}->do_background_job(
        method  => 'myapp.chat.pmessage',
        params  => {
            to_user => $args{'to_user'},
            message => $args{'message'},
        },
    );
}

1;

package MyApp::Service::DB;

use MyApp::Config;
use MyApp::Secrets;

use Curio role => '::DBIx::Connector';
use strictures 2;

key_argument 'key';
export_function_name 'myapp_db';
always_export;
export_resource;
resource_method_name 'connector';

add_key 'main';
add_key 'analytics';

has key => (
    is       => 'ro',
    required => 1,
);

sub dsn {
    my ($self) = @_;
    return myapp_config()->{db}->{ $self->key() }->{dsn};
}

sub username {
    my ($self) = @_;
    return myapp_config()->{db}->{ $self->key() }->{username};
}

sub password {
    my ($self) = @_;
    return myapp_secret( $self->key() . '_' . $self->username() );
}

sub attributes {
    return { PrintError=>1 };
}

1;

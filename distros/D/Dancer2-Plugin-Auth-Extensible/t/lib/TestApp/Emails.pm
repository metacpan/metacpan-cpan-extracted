package TestApp::Emails;
use Dancer2;
use Dancer2::Plugin::Auth::Extensible;

get '/send_password_reset' => sub {
    password_reset_send username => 'dave';
};

get '/create_user/:username' => sub {
    my $username = route_parameters->get('username');
    create_user username => $username, email => 'bob@example.com', email_welcome => 1;
};

1;

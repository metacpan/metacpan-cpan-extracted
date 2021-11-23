package MyApp::Controller::Users;
use Dancer2 appname => 'MyApp';

get '/users' => sub {
    return '/users';
};

true;

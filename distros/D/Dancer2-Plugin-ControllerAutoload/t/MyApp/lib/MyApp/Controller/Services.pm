package MyApp::Controller::Services;
use Dancer2 appname => 'MyApp';

get '/services' => sub {
    return '/services';
};

true;

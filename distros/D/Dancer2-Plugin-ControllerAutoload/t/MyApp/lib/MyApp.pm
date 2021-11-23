package MyApp;
use Dancer2;
our $VERSION = '0.1';
use Dancer2::Plugin::ControllerAutoload;

get '/' => sub {
    return 'root';
};

true;

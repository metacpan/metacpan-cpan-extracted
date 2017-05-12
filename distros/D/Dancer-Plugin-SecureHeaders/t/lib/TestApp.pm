package t::lib::TestApp;
use Dancer;
set session => 'simple';

use Dancer::Plugin::SecureHeaders;

our $VERSION = '0.1';

get '/' => sub {
    return 'Index ok';
};

get '/manual' => sub {
    header 'X-XSS-Protection' => '1';
};

true;

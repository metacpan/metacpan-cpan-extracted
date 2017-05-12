package t::lib::MyApp;

use Dancer;
use Dancer::Plugin::EmptyGIF;

get '/empty.gif' => sub {
    return empty_gif;
};

1;
package t::lib::WebService;

use Dancer;
use Dancer::Plugin::SporeDefinitionControl;

check_spore_definition();


    get '/nimportequoi/:id' => sub { "OK" };
    get '/object/:id' => sub { "OK" };
    post '/nimportequoi' => sub { "OK" };
    post '/object' => sub { "OK" };
    post '/anotherobject' => sub { "OK" };
    put '/nimportequoi/:id' => sub { "OK" };
    put '/object/:id' => sub { "OK" };
    del '/nimportequoi/:id' => sub { "OK" };
    del '/object/:id' => sub { "OK" };

1;

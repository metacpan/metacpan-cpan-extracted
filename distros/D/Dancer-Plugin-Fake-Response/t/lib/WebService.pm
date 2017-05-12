package t::lib::WebService;

use Dancer;
use Dancer::Plugin::Fake::Response;

catch_fake_exception();

    get '/rewrite_fake_route/:id.:format' => sub { "OK" };
    get '/object/:id.:format' => sub { "OK" };
    post '/rewrite_fake_route/:format' => sub { "OK" };
    post '/object/:format' => sub { "OK" };
    put '/rewrite_fake_route/:id.:format' => sub { "OK" };
    put '/object/:id.:format' => sub { "OK" };
    del '/rewrite_fake_route/:id.:format' => sub { "OK" };
    del '/object/:id.:format' => sub { "OK" };

1;

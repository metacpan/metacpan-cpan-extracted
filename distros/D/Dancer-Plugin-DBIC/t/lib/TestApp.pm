package t::lib::TestApp;

use Dancer;
use Dancer::Plugin::DBIC qw(rset);

get '/' => sub { rset('User')->count };

get '/user/:name' => sub { rset('User')->find( param 'name' )->name };

del '/user/:name' => sub {
    rset('User')->find( param 'name' )->delete;
    return 'ok';
};

1;

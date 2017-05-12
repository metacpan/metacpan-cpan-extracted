package t::lib::TestApp;

use Dancer2;
use Dancer2::Plugin::DBIC;

get '/' => sub {
    my $total_user = schema->resultset('User')->search();
    $total_user->count();
};

get '/user/:id' => sub {
    my $user = schema->resultset('User')->find( params->{id} );
    $user->name;
};

del '/user/:id' => sub {
    schema->resultset('User')->find( params->{id} )->delete;
    'ok';
};

1;

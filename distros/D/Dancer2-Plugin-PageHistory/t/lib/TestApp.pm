package TestApp;

use strict;
use warnings;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't';
    $ENV{DANCER_ENVDIR}  = 't/environments';
}

use Dancer2;
use Dancer2::Plugin::PageHistory;

#isa_ok( session, "Dancer2::Session::$engine" );

get '/session/class' => sub {
    my $session = session;
    return ref($session);
};

get '/session/destroy' => sub {
    app->destroy_session;
    return "destroyed";
};

get '/product/**' => sub {
    add_to_history( type => 'product' );
    pass;
};

get '/**' => sub {
    content_type('application/json');
    return to_json( session('page_history') );
};

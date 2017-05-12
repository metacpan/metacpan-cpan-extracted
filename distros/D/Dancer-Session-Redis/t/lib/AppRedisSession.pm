package t::lib::AppRedisSession;

use strict;
use warnings;
use Dancer ':syntax';

my $session_key = 'AppRedisSession';

get '/' => sub {  $session_key };

prefix '/session';

get '/id'      => sub { session->id };
get '/name'    => sub { session->session_name };
get '/destroy' => sub { session->destroy };

prefix '/names';

get '/get' => sub  {
    session $session_key;
};

get '/set/:name' => sub  {
    my $name = params->{name};

    my $names = session $session_key;
    push @$names, $name;
    session $session_key => $names;

    $name;
};

get '/clear' => sub  {
    session $session_key => [];
    ';-)';
};

1; # End of t::lib::AppRedisSession

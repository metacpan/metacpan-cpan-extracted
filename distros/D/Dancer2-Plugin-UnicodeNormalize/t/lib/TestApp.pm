package t::lib::TestApp;

use Dancer2;
use Dancer2::Plugin::UnicodeNormalize;
use Unicode::Char;
my $u = Unicode::Char->new();

set charset => 'UTF-8';
set apphandler => 'PSGI';
set log => 'error';

get '/cmp/:string1/:string2' => sub {
    return 'missing parameter!' unless ( param('string1') && param('string2') );
    return ( ( param('string1') eq param('string2') ) ? 'eq' : 'ne' );
};

get '/cmp_route/:string1/:string2' => sub {
    return 'missing parameter!' unless ( route_parameters->get('string1') && route_parameters->get('string2') );
    return ( ( route_parameters->get('string1') eq route_parameters->get('string2') ) ? 'eq' : 'ne' );
};

get '/cmp_query' => sub {
    return 'missing parameter!' unless ( query_parameters->get('string1') && query_parameters->get('string2') );
    return ( ( query_parameters->get('string1') eq query_parameters->get('string2') ) ? 'eq' : 'ne' );
};

post '/cmp' => sub {
    return 'missing parameter!' unless ( param('string1') && param('string2') );
    return ( ( param('string1') eq param('string2') ) ? 'eq' : 'ne' );
};

post '/cmp_body' => sub {
    return 'missing parameter!' unless ( body_parameters->get('string1') && body_parameters->get('string2') );
    return ( ( body_parameters->get('string1') eq body_parameters->get('string2') ) ? 'eq' : 'ne' );
};

post '/upload' => sub {
    my ($file1, $file2) = (upload('file1'), upload('file2'));
    return ( ( $file1->content eq $file2->content ) ? 'eq' : 'ne' );
};

get '/form/:string' => sub {
    return param('string');
};

get '/optional/:string?' => sub {
    return 'success';
};

1;


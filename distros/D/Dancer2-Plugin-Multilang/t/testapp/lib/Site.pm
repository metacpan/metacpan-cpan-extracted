package Site;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/testapp/lib";
use Dancer2;
use Dancer2::Plugin::Multilang;

get '/' => sub {
    return language;
};      
get '/page' => sub {
    return 'page-' . language;
};
get '/second' => sub {
    return 'second-' . language;
};
get '/free' => sub {
    return 'no-lan'
};

1;


package Cache;

use Dancer2;

BEGIN {
    set public_dir => './t/lib',
    set plugins => { 
        FontSubset => { 
            use_cache => 1,
            fonts_dir => 'fonts',
        }, 
        'Cache::CHI' => {
            driver => 'Memory',
            global => 1,
        },
    };

   set show_warnings => 1;
   set logger => 'console';

}

use Dancer2::Plugin::FontSubset;
use Dancer2::Plugin::Cache::CHI;

get '/cached' => sub {
    cache_get( 'font-./t/lib/fonts/Bocklin.ttf-102111' );
};

get '/fake' => sub {
    cache_set( 'font-./t/lib/fonts/Bocklin.ttf-102111', "faked" );
};


1;

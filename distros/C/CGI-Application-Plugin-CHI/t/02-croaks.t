#!perl -T

use strict;
use warnings;

use Test::More tests => 10;

use_ok( 'CGI::Application::Plugin::CHI' );

# cache_config croaks
eval { 
     main->cache_config( [ ] );
};

like( $@, qr/a hashref or cache name/ );
clean();

eval { 
     main->cache_config( foo => { }, bar => { }, baz => 'narf' );
};

like( $@, qr/requires name => hashref pairs/ );
clean();

eval { 
    main->cache_config;
};

like( $@, qr/no arguments to cache_config/ );
clean();

# cache_default croaks
eval { 
    main->cache_default( 'foo', 'bar' );
};

like( $@, qr/requires one argument/ );
clean();

eval { 
    main->cache_default( 'does not exist' );
};

like( $@, qr/no such cache named 'does not exist'/ );
clean();

# cache croaks
eval { 
    main->cache;
};

like( $@, qr/called as an object method/ );

my $obj = bless { }, 'main';
eval { 
    $obj->cache
};

like( $@, qr/no default cache configured/ );

eval { 
    $obj->cache( "Foo" );
};

like( $@, qr/no such cache 'Foo' configured/ );

eval { 
    $obj->cache( 1, 2, 3 );
};

like( $@, qr/too many arguments/ );




sub clean { 
    CGI::Application::Plugin::CHI->_clean_conf;
}


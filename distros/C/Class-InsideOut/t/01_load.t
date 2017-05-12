use strict;
use lib ".";

my (@api, @not_api);

BEGIN {
    @api = qw(
        options
        private
        property
        public
        register
        id
        _properties
        _object_count
        _leaking_memory
        CLONE
    );

    @not_api = qw(
        DESTROY
        STORABLE_freeze 
        STORABLE_thaw
    );
}

use Test::More tests =>  1 + @api + @not_api ;

$|++; # keep stdout and stderr in order on Win32

BEGIN { use_ok( 'Class::InsideOut' ); }

can_ok( 'Class::InsideOut', $_ ) for @api;

for ( @not_api ) {
    ok( ! Class::InsideOut->can( $_ ), "$_ not part of the API" );
}
    

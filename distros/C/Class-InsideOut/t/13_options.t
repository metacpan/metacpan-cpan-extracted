use strict;
use lib ".";
use Test::More tests =>  5;

$|++; # keep stdout and stderr in order on Win32

BEGIN { use_ok( 'Class::InsideOut', 'options' ); }

can_ok( 'main', 'options' );

is_deeply( { options() }, {},
    "No options set"
);

ok( options( {privacy => 'public'} ),
    "Setting options"
);

is_deeply( { options() }, { privacy => 'public' } ,
    "options() provides current options"
);


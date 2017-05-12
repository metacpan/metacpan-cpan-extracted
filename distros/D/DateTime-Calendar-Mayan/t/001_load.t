use strict;
use warnings;

use Test::More tests => 6;

BEGIN { use_ok( 'DateTime' ); }
BEGIN { use_ok( 'DateTime::Duration' ); }
BEGIN { use_ok( 'DateTime::Calendar::Mayan' ); }

{
    my $object = DateTime->now();
    isa_ok ($object, 'DateTime');
}

{
    my $object = DateTime::Duration->new();
    isa_ok ($object, 'DateTime::Duration');
}

{
   my $object = DateTime::Calendar::Mayan->new();
   isa_ok ($object, 'DateTime::Calendar::Mayan');
}

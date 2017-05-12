#

use strict;
use lib qw(blib);
use Data::SimplePassword;

use Test::More;

BEGIN { use_ok( 'Data::SimplePassword' ) }

ok( Data::SimplePassword->class, "class name" );
diag( "Using " . Data::SimplePassword->class );

BAIL_OUT("couldn't find any suitable MT classes !!")
    if Data::SimplePassword->class !~ /^Math::Random::MT/;

can_ok( 'Data::SimplePassword', 'new' );
ok( Data::SimplePassword->new, "" );

done_testing;

__END__

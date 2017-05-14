use strict;
use warnings;

use Test::More;

use App::PigLatin qw(translate);

my $text;

$text = 'test';
is( translate(\$text), 'esttay', 'test a single lower-case string' );

#SKIP: {
#    # test single upper-case string
#    $text = "TEST";
#    is ( translate(\$text), "ESTTAY", 'TEST should be ESTTAY' );
#};

$text = 'Test';
is( translate(\$text), 'Esttay', 'test a single first letter upper-case string' );

$text = 'This is a test my name is Peter Parker';
is( translate(\$text), 'Isthay isay aay esttay myay amenay isay Eterpay Arkerpay', 'test a muliti-word string' );

done_testing;

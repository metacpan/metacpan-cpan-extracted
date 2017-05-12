use strict;
use warnings;
use Test::More tests => 3;

use Data::Context::Actions;

actions();

done_testing();

sub actions {
    my $val = Data::Context::Actions->expand_vars( 'a', { a => 1 }, 'a.b.c' );
    is $val, 1, 'Action expanded var';

    $val = Data::Context::Actions->expand_vars( '#a#', { a => 1 }, 'a.b.c' );
    is $val, 1, 'Action expanded var';

    $val = Data::Context::Actions->expand_vars( {value => 'a'}, { a => 1 }, 'a.b.c' );
    is $val, 1, 'Action expanded var';
}

use strict;
use warnings;
use Test::More;
use Alien::Chipmunk;

diag( 'NAME=' . Alien::Chipmunk->config('name') );
diag( 'VERSION=' . Alien::Chipmunk->config('version') );

my $alien = Alien::Chipmunk->new;

diag( 'CFLAGS=' . $alien->cflags );
diag( 'LIBS=' . $alien->libs );

SKIP: {
    skip "system libs may not need -I or -L", 2
        if $alien->install_type('system');
    like( $alien->cflags, qr/-I/ );
    like( $alien->libs,   qr/-L/ );
}

done_testing();


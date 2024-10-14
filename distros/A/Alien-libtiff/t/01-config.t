use 5.010;
use strict;
use warnings;
use Test::More;
use Alien::libtiff;

diag( 'NAME=' . Alien::libtiff->config('name') // '' );
diag( 'VERSION=' . Alien::libtiff->config('version') );

my $alien = Alien::libtiff->new;

diag 'CFLAGS: ' . $alien->cflags;

SKIP: {
    skip "system libs may not need -I or -L", 2
        if $alien->install_type('system');
    like( $alien->cflags // '', qr/-I/ , 'cflags');
    like( $alien->libs // '',   qr/-L/ , 'libs');
}


done_testing();


use strict;
use warnings;
use Test::More;
use Alien::Proj4;

diag( 'NAME=' . Alien::Proj4->config('name') );
diag( 'VERSION=' . Alien::Proj4->config('version') );

my $alien = Alien::Proj4->new;

diag 'CFLAGS: ' . $alien->cflags;

SKIP: {
    skip "system libs may not need -I or -L", 2
        if $alien->install_type('system');
    like( $alien->cflags // '', qr/-I/ , 'cflags');
    like( $alien->libs // '',   qr/-L/ , 'libs');
}


done_testing();


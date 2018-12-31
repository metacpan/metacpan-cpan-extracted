use strict;
use warnings;
use Test::More;
use Alien::freexl;

diag( 'NAME=' . Alien::freexl->config('name') );
diag( 'VERSION=' . Alien::freexl->config('version') );

my $alien = Alien::freexl->new;

diag 'CFLAGS: ' . $alien->cflags;

SKIP: {
    skip "system libs may not need -I or -L", 2
        if $alien->install_type('system');
    like( $alien->cflags // '', qr/-I/ , 'cflags');
    like( $alien->libs // '',   qr/-L/ , 'libs');
}


done_testing();


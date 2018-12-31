use strict;
use warnings;
use Test::More;
use Alien::sqlite;

diag( 'NAME=' . Alien::sqlite->config('name') );
diag( 'VERSION=' . Alien::sqlite->config('version') );

my $alien = Alien::sqlite->new;

diag 'CFLAGS: ' . $alien->cflags;

SKIP: {
    skip "system libs may not need -I or -L", 2
        if $alien->install_type('system');
    like( $alien->cflags // '', qr/-I/ , 'cflags');
    like( $alien->libs // '',   qr/-L/ , 'libs');
}


done_testing();


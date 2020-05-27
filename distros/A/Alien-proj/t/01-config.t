use strict;
use warnings;
use Test::More;
use Alien::proj;

diag( 'NAME=' . Alien::proj->config('name') // '(no name confg param)');
diag( 'VERSION=' . Alien::proj->config('version') );

my $alien = Alien::proj->new;

diag 'CFLAGS: ' . $alien->cflags;

SKIP: {
    skip "system libs may not need -I or -L", 2
        if $alien->install_type('system');
    like( $alien->cflags // '', qr/-I/ , 'cflags');
    like( $alien->libs // '',   qr/-L/ , 'libs');
}


done_testing();


use strict;
use warnings;
use Test::More;
use Alien::freexl;

diag( 'NAME=' . Alien::freexl->config('name') );
diag( 'VERSION=' . Alien::freexl->config('version') );
diag( 'Install type=' . Alien::freexl->install_type );

my $alien = Alien::freexl->new;

diag 'cflags: ' . $alien->cflags;
diag 'libs:   ' . $alien->libs;

if (not $alien->install_type('system')) {
    like( $alien->cflags // '', qr/-I/ , 'cflags');
    like( $alien->libs // '',   qr/-L/ , 'libs');
}
else {
    ok (1, 'no cflags or libs for system installs');
}


done_testing();


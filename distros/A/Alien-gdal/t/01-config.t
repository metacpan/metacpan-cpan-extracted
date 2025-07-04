use strict;
use warnings;
use Test::More;
use Alien::gdal;
use Sort::Versions;

diag( 'NAME=' . Alien::gdal->config('name') );
diag( 'VERSION=' . Alien::gdal->config('version') );

my $alien = Alien::gdal->new;

# If all these are system libs then cflags and libs differ from expectations
# Should really run different tests... 
my @aliens_to_check = qw /Alien::sqlite Alien::libtiff Alien::proj/;
my $system_aliens;
foreach my $alien (@aliens_to_check) {
    my $have = eval "require $alien";
    next if !$have;
    if ($alien->install_type('system')) {
       $system_aliens ++;
    }
}

SKIP: {
    skip "system libs may not need -I or -L", 2
        if   $alien->install_type('system')
          or $system_aliens == @aliens_to_check;
    like( $alien->cflags, qr/-I/ , 'cflags');
    like( $alien->libs,   qr/-L/ , 'libs');
}

done_testing();


use strict;
use warnings;
use Test::More;
use Alien::gdal;

diag( 'NAME=' . Alien::gdal->config('name') );
diag( 'VERSION=' . Alien::gdal->config('version') );

my $alien = Alien::gdal->new;

SKIP: {
    skip "system libs may not need -I or -L", 2
        if $alien->install_type('system');
    like( $alien->cflags, qr/-I/ , 'cflags');
    like( $alien->libs,   qr/-L/ , 'libs');
}

TODO: {
    local $TODO = 'data_dir does not work across all platforms yet';
    my $data_dir = eval {$alien->data_dir};
    diag $@ if $@;
    diag "Data dir is $data_dir";
    ok ($data_dir && -d $data_dir, "data dir exists (" . ($data_dir // '') . ")");
    ok ($data_dir && -e "$data_dir/gcs.csv", "Found coordinate systems file (gcs.csv)");
}

done_testing();


use strict;
use warnings;
use Test::More;
use Alien::gdal;
use Sort::Versions;

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
    if (versioncmp (Alien::gdal->version, 3) < 0) {
        #  does not exist under 3.0 and higher
        ok ($data_dir && -e "$data_dir/gcs.csv", "Found coordinate systems file (gcs.csv)");
    }
}

done_testing();


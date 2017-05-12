# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Catalyst-View-GD-Barcode.t'

#########################

use Test::More tests => 2;
BEGIN {
    use_ok('Catalyst::View::GD::Barcode');
    use_ok('GD::Barcode');
};


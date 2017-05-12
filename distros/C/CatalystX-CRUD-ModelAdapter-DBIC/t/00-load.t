#!perl -T

use Test::More tests => 1;
use lib qw( ../../CatalystX-CRUD/trunk/lib t );

BEGIN {
    use_ok('CatalystX::CRUD::ModelAdapter::DBIC');
}

diag(
    "Testing CatalystX::CRUD::ModelAdapter::DBIC $CatalystX::CRUD::ModelAdapter::DBIC::VERSION, Perl $], $^X"
);

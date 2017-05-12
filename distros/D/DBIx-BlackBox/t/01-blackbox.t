
use strict;
use warnings;

use Test::More tests => 11;

use Test::NoWarnings;
use Test::Exception;


use lib qw( t/lib );

BEGIN { use_ok('MyDBBB') };

my $dbbb;

lives_ok {
    $dbbb = MyDBBB->new();
} "instance created successfully";

my @procedure_classes = qw(
    MyDBBB::Procedures::ErrorTest
    MyDBBB::Procedures::ErrorTest2
    MyDBBB::Procedures::ErrorTest3
);

my @resultset_classes = qw(
    MyDBBB::ResultSet::Catalogs
    MyDBBB::ResultSet::CatalogData
);

is( Class::MOP::is_class_loaded( $_ ), 1, "class $_ automatically loaded")
    for @procedure_classes, @resultset_classes;


is( $_->meta->does_role('DBIx::BlackBox::Procedure'), 1,
    "procedure class $_ consumes DBIx::BlackBox::Procedure")
        for @procedure_classes;


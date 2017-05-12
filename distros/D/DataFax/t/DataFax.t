# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use DataFax;
my $class = 'DataFax';
my $obj = DataFax->new; 

isa_ok($obj, "DataFax");

diag("Test export_ok'ed methods...");
foreach my $m (@DataFax::EXPORT_OK) {
    ok($obj->can($m), "$class->can('$m')");
}
diag("Test imported methods...");
foreach my $m (@DataFax::IMPORT_OK) {
    ok($obj->can($m), "$class->can('$m')");
}
diag("Test import tag methods...");
foreach my $k (sort keys %DataFax::EXPORT_TAGS) {
    foreach my $i (0..$#{$DataFax::EXPORT_TAGS{$k}}) {
        my $m = $DataFax::EXPORT_TAGS{$k}[$i]; 
        ok($obj->can($m), "$k: $class->can('$m')");
    }
}

1;


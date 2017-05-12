# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use CGI::AppBuilder;
my $class = 'CGI::AppBuilder';
my $obj = CGI::AppBuilder->new; 

isa_ok($obj, "CGI::AppBuilder");

diag("Test export_ok'ed methods...");
foreach my $m (@CGI::AppBuilder::EXPORT_OK) {
    ok($obj->can($m), "$class->can('$m')");
}
diag("Test imported methods...");
foreach my $m (@CGI::AppBuilder::IMPORT_OK) {
    ok($obj->can($m), "$class->can('$m')");
}

1;


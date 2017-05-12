# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use DataFax::StudySubs; 

my $self  = bless {}, "main"; 
my $class = "DataFax::StudySubs"; 
my $obj = bless {} , ref($class)||$class; 

isa_ok($obj, $class);

my @md = (@DataFax::StudySubs::EXPORT_OK);
foreach my $m (@md) {
    ok($obj->can($m), "$class->can('$m')");
}

1;


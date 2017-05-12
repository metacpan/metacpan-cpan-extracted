#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Dumper;
use DBICx::TestDatabase;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/tlib";

use Icydee::MockCatalyst;
use Icydee::TestObject;

BEGIN {
    use_ok('TestSchema');
    use_ok('Catalyst::TraitFor::Controller::jQuery::jqGrid');
}

my $schema = DBICx::TestDatabase->new('TestSchema');
isa_ok($schema, 'DBIx::Class::Schema');

my $table = $schema->resultset('Gridable')->search({},{order_by => 'id'});
isa_ok($table, 'DBIx::Class::ResultSet', 'Object is a DBIx::Class::ResultSet');

# Create some test data
for my $row (1..15) {
    my $row = $table->create({
        id      => $row,
        column1 => "row $row column 1",
        column2 => "row $row column 2",
        column3 => "row $row column 3",
    });
}

is($table->count, 15, "Correct number of rows");

# Create a mock Catalyst object
my $c = Icydee::MockCatalyst->new;
#$c->set_action('foo');
#$c->set_config({
#    'Catalyst::TraitFor::Controller::jQuery::jqGrid' => {
#        page        => 'page',
#        rows        => 'rows',
#        sidx        => 'sidx',
#        sord        => 'sord',
#        json_data   => 'json_data',
#    },
#});

# Try it first using the default configuration

# Object which uses the Role
my $followed = Icydee::TestObject->new;

$table = $followed->jqgrid_page($c, $table);
isa_ok($table, 'DBIx::Class::ResultSet', 'Still is a DBIx::Class::ResultSet');

# default page size is 10
is($table->count, 10, "One page of rows");

# Should be rows 1 to 10
my $id = 1;
while (my $row = $table->next) {
    is($row->id, $id, "Correct id $id");
    $id++;
}

#############################
### TODO Many more tests! ###
#############################

done_testing();
exit;

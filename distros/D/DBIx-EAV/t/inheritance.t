#!/usr/bin/perl -w
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::DBIx::EAV;


my $eav = DBIx::EAV->new(
    dbh => get_test_dbh, tenant_id => 42,
    static_attributes => [qw/ is_deleted:bool::0 is_active:bool::1 is_published:bool::1 /]
);
$eav->schema->deploy( add_drop_table => $eav->schema->db_driver_name eq 'mysql');
$eav->register_types(read_yaml_file("$FindBin::Bin/ecommerce.yml"));


my $product  = $eav->type('Product');
my $harddisk = $eav->type('HardDisk');
my $monitor  = $eav->type('Monitor');
my $curved_monitor  = $eav->type('CurvedMonitor');

# parent
is $product->has_parent, '', 'type->has_parent';
is $monitor->has_parent, 1, 'subtype->has_parent';
is $monitor->parent->name, 'Product', 'subtype->parent';
is $curved_monitor->parent->name, 'Monitor', 'subtype2->parent';

is [map { $_->name } $curved_monitor->parents],
          [qw/ Monitor Product /], 'parents';

ok $product->is_type('Product'), 'is_type';
ok $monitor->is_type('Product'), 'is_type';
ok $curved_monitor->is_type('Product'), 'is_type';
ok $curved_monitor->is_type('Monitor'), 'is_type';
ok $curved_monitor->is_type('CurvedMonitor'), 'is_type';

# inherited relationship
is $harddisk->relationship('tags')->{id}, $product->relationship('tags')->{id}, 'child type shares parent relationship';

# inherited attributes
is $harddisk->has_inherited_attribute('name'), 1, 'has_inherited_attribute';
is $harddisk->has_own_attribute('capacity'), 1, 'has_own_attribute';

is $harddisk->attribute('name')->{id}, $product->attribute('name')->{id}, 'child type1 shares attr1 with parent type';
is $harddisk->attribute('description')->{id}, $product->attribute('description')->{id}, 'child type1 shares attr2 with parent type';

is $monitor->attribute('name')->{id}, $product->attribute('name')->{id}, 'child type2 shares attr1 with parent type';
is $monitor->attribute('description')->{id}, $product->attribute('description')->{id}, 'child type2 shares attr2 with parent type';

is $curved_monitor->attribute('name')->{id}, $product->attribute('name')->{id}, 'child type3 shares attr1 with root parent type';
is $curved_monitor->attribute('description')->{id}, $product->attribute('description')->{id}, 'child type3 shares attr2 with root parent type';

is $curved_monitor->attribute('resolution')->{id}, $monitor->attribute('resolution')->{id}, 'child type3 shares attr1 with parent type';
is $curved_monitor->attribute('contrast_ratio')->{id}, $monitor->attribute('contrast_ratio')->{id}, 'child type3 shares attr2 with parent type';

is [sort $harddisk->attributes( names => 1 )],
          [qw/ capacity description entity_type_id id is_active is_deleted is_published name price rpm /],
          'attributes( names => 1)';


# inheritance table
ok $eav->table('type_hierarchy')->select_one({ parent_type_id => $product->id, child_type_id => $harddisk->id }), 'harddisk entry on hierarchy table';
ok $eav->table('type_hierarchy')->select_one({ parent_type_id => $product->id, child_type_id => $monitor->id }), 'monitor entry on hierarchy table';
ok $eav->table('type_hierarchy')->select_one({ parent_type_id => $monitor->id, child_type_id => $curved_monitor->id }), 'curvedmonitor entry on hierarchy table';


# populate
my @tags = $eav->resultset('Tag')->populate([map { +{ name => 'Tag'.$_ } } 1..3 ]);

$eav->resultset('HardDisk')->populate([
    { name => 'HardDisk1', price => 100, capacity => 1000, tags => \@tags },
    { name => 'HardDisk2', price => 200, capacity => 2000, tags => \@tags },
    { name => 'HardDisk3', price => 300, capacity => 3000, tags => \@tags }
]);

$eav->resultset('Monitor')->populate([
    { name => 'Monitor1', price => 100, contrast_ratio => 10000, tags => \@tags },
    { name => 'Monitor2', price => 200, contrast_ratio => 20000, tags => \@tags },
    { name => 'Monitor3', price => 300, contrast_ratio => 30000, tags => \@tags }
]);

$eav->resultset('CurvedMonitor')->populate([
    { name => 'CurvedMonitor1', price => 100, contrast_ratio => 10000, angle => 10000 },
    { name => 'CurvedMonitor2', price => 200, contrast_ratio => 20000, angle => 20000 },
    { name => 'CurvedMonitor3', price => 300, contrast_ratio => 30000, angle => 30000 }
]);

$eav->resultset('FancyMonitor')->populate([
    { name => 'FancyMonitor1', price => 100 },
    { name => 'FancyMonitor2', price => 200 },
    { name => 'FancyMonitor3', price => 300 }
]);


# find subproducts
my $products = $eav->resultset('Product');
my @result = $products->search({ price => { '>' => 200 } }, { order_by => 'name', subtype_depth => 1 })->all;
is [map { $_->get('name') } @result], [qw/ HardDisk3 Monitor3 /], 'find subtypes';
is $result[0]->type->name, 'HardDisk', 'result item0 inflated to correct subtype';

@result = $products->search({ price => { '>' => 200 } }, { order_by => 'name', subtype_depth => 2 })->all;
is [map { $_->get('name') } @result], [qw/ CurvedMonitor3 HardDisk3 Monitor3 /], 'find subtypes depth 2';

@result = $products->search({ price => { '>' => 200 } }, { order_by => 'name', subtype_depth => 3 })->all;
is [map { $_->get('name') } @result], [qw/ CurvedMonitor3 FancyMonitor3 HardDisk3 Monitor3 /], 'find subtypes depth 3';


# resultset->delete on subtype
$eav->resultset('Monitor')->delete;

my $hd = $eav->resultset('HardDisk')->search->next;
is $hd->get('name'), 'HardDisk1', 'resultset->delete keeps sibiling attrs';

my $cm = $eav->resultset('CurvedMonitor')->search->next;
is $cm->get('contrast_ratio'), 10000, 'resultset->delete keeps subtype attrs';

is $hd->get('tags')->count, 3, 'resultset->delete on subtype (rels)';


done_testing;

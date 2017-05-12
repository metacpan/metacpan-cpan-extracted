#!/usr/bin/perl
#This is in "scripts/tree_example.pl" of DBIx::Tree::NestedSet distribution
use strict;
use warnings;
use DBIx::Tree::NestedSet;
use DBI;

#Create the connection. We'll use SQLite for now.
#my $dbh=DBI->connect('DBI:mysql:test','user','pass') or die ($DBI::errstr);
my $dbh=DBI->connect('DBI:SQLite:test') or die ($DBI::errstr);

my $db_type='SQLite';
#my $db_type='MySQL';
my $tree=DBIx::Tree::NestedSet->new(
				    dbh=>$dbh,
				    table_name=>'food',
				    db_type=>$db_type
				   );

#Let's see how the table will be created for this driver
#print "Default Create Table Statement for $db_type:\n";
#print $tree->get_default_create_table_statement()."\n";

#Let's create it.
$tree->create_default_table();

#Create the root node.
my $root_id=$tree->add_child_to_right(name=>'Food');

#Second level
my $vegetable_id=$tree->add_child_to_right(id=>$root_id,name=>'Vegetable');
my $animal_id=$tree->add_child_to_right(id=>$root_id,name=>'Animal');
my $mineral_id=$tree->add_child_to_right(id=>$root_id,name=>'Mineral');

#Third Level, under "Vegetable"
foreach ('Froot','Beans','Legumes','Tubers') {
    $tree->add_child_to_right(id=>$vegetable_id,name=>$_);
}

#Third Level, under "Animal"
foreach ('Beef','Chicken','Seafood') {
    $tree->add_child_to_right(id=>$animal_id,name=>$_);
}

#Hey! We forgot pork! Since it's the other white meat,
#it should be first among the "Animal" crowd.
$tree->add_child_to_left(id=>$animal_id,name=>'Pork');

#Oops. Misspelling.
$tree->edit_node(
		 id=>$tree->get_id_by_key(key_name=>'name',key_value=>'Froot'),
		 name=>'Fruit'
		);

#Get the child nodes of the 2nd level "Animal" node
my $children=$tree->get_self_and_children_flat(id=>$animal_id);

#Grab the first node, which is "Animal" and the
#parent of this subtree.
my $parent=shift @$children;

print 'Parent Node: '.$parent->{name}."\n";

#Loop through the children and do something.
foreach my $child (@$children) {
    print ' Child ID: '.$child->{id}.' '.$child->{name}."\n";
}

#Mineral? Get rid of it.
$tree->delete_self_and_children(id=>$mineral_id);

$dbh->do('create table nutrition (food_id int not null primary key,description text not null)');
my $insert_nutrition=$dbh->prepare('insert into nutrition(food_id,description) values(?,?)');
my $food=$tree->get_self_and_children_flat();
foreach my $food_item(@$food) {
    $insert_nutrition->execute($food_item->{id},$food_item->{name}." is/are good for you, in moderation");
}

#Normally you wouldn't look up a nodes value by key, but you can.
#you'll know the node id because you're browsing the hierarchy.

my $veggie_info=$tree->get_hashref_of_info_by_id($tree->get_id_by_key(key_name=>'name',key_value=>'Vegetable'));

my $vegetables_without_level=$dbh->selectall_arrayref(q|
select food.name,nutrition.description from food,nutrition
where
food.id=nutrition.food_id and
food.lft between ? and ?|,{Columns=>{}},($veggie_info->{lft},$veggie_info->{rght}));

print "\nVeggie info without level information:\n";
foreach (@$vegetables_without_level) {
    print $_->{description}."\n";
}


my $vegetables_with_level=$dbh->selectall_arrayref(q|
select count(n2.id) as level,nutrition.description,n1.* 
from food as n1, food as n2, nutrition 
where (n1.lft between n2.lft and n2.rght) 
and (n1.lft between ? and ?)
and nutrition.food_id=n1.id
group by n1.id order by n1.lft|,{Columns=>{}},($veggie_info->{lft},$veggie_info->{rght}));

print "\nVeggie info with level information:\n";
foreach (@$vegetables_with_level) {
    print "Level: ".$_->{level}."\t".$_->{description}."\n";
}


#Print the rudimentary report built into the module.
print "\nThe Complete Tree:\n";
print $tree->create_report();

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use DBIx::Tree::NestedSet();
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

################################################################################
# Get the password and DSN info and connect to datasource
open (PWD, "PWD") 
  or (print "not ok 2\n" and die "Could not open PWD for reading!");
my $increment=0;
my $rdbms;
while(<PWD>) {
    chomp;
    if ($increment == 0) {
	$rdbms=$_;
    } else {
	push @dbiparms, $_;	
    }
    $increment++;
}
close (PWD);

use DBI;
my $dbh = DBI->connect(@dbiparms);
if ( defined $dbh ) {
    print "ok 2\n";
} else {
    print "not ok 2\n";
    die $DBI::errstr;
}


################################################################################
# Create the object
my $tree=DBIx::Tree::NestedSet->new(dbh=>$dbh,db_type=>$rdbms);

if (defined $tree) {
    print "ok 3\n";
} else {
    print "not ok 3\n";
}

################################################################################
# Create the table.
my $status=$tree->create_default_table();

if ( defined $status ) {
    print "ok 4\n";
} else {
    print "not ok 4\n";
    die $DBI::errstr;
}


################################################################################
# Create the root node
$tree->add_child_to_right(name=>'Root');

if (compare_tree($dbh,[
		       {lft=>1,rght=>2,name=>'Root'}
		      ])
   ) {
    print "ok 5\n";
}  else {
    print "not ok 5\n";
    die $DBI::errstr;
}

################################################################################
# Add a children to the right
$tree->add_child_to_right(id=>$tree->get_root(),name=>'Right Child 1');
$tree->add_child_to_right(id=>$tree->get_root(),name=>'Right Child 2');
$tree->add_child_to_right(id=>$tree->get_root(),name=>'Right Child 3');

if (compare_tree($dbh,[
		       {lft=>1,rght=>8,name=>'Root'},
		       {lft=>2,rght=>3,name=>'Right Child 1'},
		       {lft=>4,rght=>5,name=>'Right Child 2'},
		       {lft=>6,rght=>7,name=>'Right Child 3'}
		      ])
   ) {
    print "ok 6\n";
}  else {
    print "not ok 6\n";
    die $DBI::errstr;
}

################################################################################
# Add children to the left
$tree->add_child_to_left(id=>$tree->get_root(),name=>'Left Child 1');
$tree->add_child_to_left(id=>$tree->get_id_by_key(key_name=>'name',key_value=>'Right Child 2'),name=>'First Left Sub-Child of Right Child 2');
$tree->add_child_to_left(id=>$tree->get_id_by_key(key_name=>'name',key_value=>'Right Child 2'),name=>'Second Left Sub-Child of Right Child 2');

if (compare_tree($dbh,[
		       {'rght' => '14',	'name' => 'Root','lft' => '1'},
		       {'rght' => '3',	'name' => 'Left Child 1','lft' => '2'},
		       {'rght' => '5',	'name' => 'Right Child 1','lft' => '4'},
		       {'rght' => '11',	'name' => 'Right Child 2','lft' => '6'},
		       {'rght' => '8',	'name' => 'Second Left Sub-Child of Right Child 2','lft'=>'7'},
		       {'rght' => '10',	'name' => 'First Left Sub-Child of Right Child 2','lft'=>'9'},
		       {'rght' => '13',	'name' => 'Right Child 3','lft' => '12'}
		      ]
		)) {
    print "ok 7\n";
}  else {
    print "not ok 7\n";
    die $DBI::errstr;
}

################################################################################
# Swap nodes

my $first_id=$tree->get_id_by_key(key_name=>'name',key_value=>'Right Child 2');
my $second_id=$tree->get_id_by_key(key_name=>'name',key_value=>'Right Child 3');

$tree->swap_nodes(first_id=>$first_id,second_id=>$second_id);

if (compare_tree($dbh, [
			{'rght' => '14','name' => 'Root','lft' => '1'},
			{'rght' => '3','name' => 'Left Child 1','lft' => '2'},
			{'rght' => '5','name' => 'Right Child 1','lft' => '4'},
			{'rght' => '7','name' => 'Right Child 3','lft' => '6'},
			{'rght' => '13','name' => 'Right Child 2','lft' => '8'},
			{'rght' => '10','name' => 'Second Left Sub-Child of Right Child 2','lft' => '9'},
			{'rght' => '12','name' => 'First Left Sub-Child of Right Child 2','lft' => '11'}
		       ]
		)) {
    print "ok 8\n";
}  else {
    print "not ok 8\n";
    die $DBI::errstr;
}


################################################################################
# Delete nodes
my $first_delete=$tree->get_id_by_key(key_name=>'name',key_value=>'Second Left Sub-Child of Right Child 2');
my $second_delete=$tree->get_id_by_key(key_name=>'name',key_value=>'Left Child 1');

$tree->delete_self_and_children(id=>$first_delete);
$tree->delete_self_and_children(id=>$second_delete);

if (compare_tree($dbh,[
		       {'rght' => '10','name' => 'Root','lft' => '1'},
		       {'rght' => '3','name' => 'Right Child 1','lft' => '2'},
		       {'rght' => '5','name' => 'Right Child 3','lft' => '4'},
		       {'rght' => '9','name' => 'Right Child 2','lft' => '6'},
		       {'rght' => '8','name' => 'First Left Sub-Child of Right Child 2','lft' => '7'}
		      ]
		)) {
    print "ok 9\n";
}  else {
    print "not ok 9\n";
    die $DBI::errstr;
}

################################################################################
# Edit Node
my $edit_id=$tree->get_id_by_key(key_name=>'name',key_value=>'Right Child 1');

$tree->edit_node(id=>$edit_id,name=>'My New Child Name',new_column=>'Foo!');

my $node_info=$tree->get_hashref_of_info_by_id($edit_id);

if($node_info->{new_column} eq 'Foo!' && $node_info->{name} eq 'My New Child Name' ){
    print "ok 10\n";
} else {
    print "not ok 10\n";
    die $DBI::errstr;
}


################################################################################
# Get parents
my $get_parent_id=$tree->get_id_by_key(key_name=>'name',key_value=>'First Left Sub-Child of Right Child 2');

my $parents=$tree->get_self_and_parents_flat(id=>$get_parent_id);

if (compare_tree($dbh,[
		       {'rght' => '10','name' => 'Root','lft' => '1','level'=>1},
		       {'rght' => '9','level' => 2,'name' => 'Right Child 2','lft' => '6'},
		       {'rght' => '8','level' => 3,'name' => 'First Left Sub-Child of Right Child 2','lft' => '7'}
		      ],
		 $parents)) {
    print "ok 11\n";
}  else {
    print "not ok 11\n";
    die $DBI::errstr;
}

################################################################################
# Get children
my $children=$tree->get_self_and_children_flat(id=>$tree->get_root());

if (compare_tree($dbh,[
		       {'rght' => 10,'level' => 1,'name' => 'Root','lft' => 1},
		       {'rght' => 3,'level' => 2,'name' => 'My New Child Name','lft' => 2},
		       {'rght' => 5,'level' => 2,'name' => 'Right Child 3','lft' => 4},
		       {'rght' => '9','level' => '2','name' => 'Right Child 2','lft' => '6'},
		       {'rght' => '8','level' => '3','name' => 'First Left Sub-Child of Right Child 2','lft' => '7'}
		      ],
		 $children)) {
    print "ok 12\n";
}  else {
    print "not ok 12\n";
    die $DBI::errstr;
}

################################################################################
# Test non-numeric IDs
# $dbh->do('alter table nested_set modify column id varchar(50) not null');
# $tree->{no_id_creation}=1;
# $tree->add_child_to_left(id=>$tree->get_root,name=>'Non Numeric Child',provided_primary_key=>'foo_key');
# $tree->add_child_to_right(provided_primary_key=>'bar_key',name=>'Sub child of non-numeric keys',id=>'foo_key');
# $tree->add_child_to_right(provided_primary_key=>'baz_key',name=>'Sub child of non-numeric keys 2',id=>'foo_key');
# my $info=$tree->get_hashref_of_info_by_id('baz_key');
# use Data::Dumper;
# print Data::Dumper::Dumper($info);
# my $info2=$tree->get_hashref_of_info_by_id_with_level('bar_key');
# print Data::Dumper::Dumper($info2);



################################################################################
# Clean up.
#print $tree->create_report();
$dbh->do('drop table nested_set');
#unlink('PWD');


################################################################################
sub compare_tree{
    my($dbh,$test_structure,$alternate_tree_structure)=@_;
    my $full_tree=($alternate_tree_structure) ? $alternate_tree_structure : $tree->get_self_and_children_flat(id=>$tree->get_root);
    my $success=1;
    my $i=0;
    foreach my $row (@$test_structure) {
	foreach my $key(keys %$row) {
	    if ($row->{$key} != $full_tree->[$i]->{$key}) {
		$success=0;
	    }
	}
	$i++;
    }
    return $success;
}
########################################

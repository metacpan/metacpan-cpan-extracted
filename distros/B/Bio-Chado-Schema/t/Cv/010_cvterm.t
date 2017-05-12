#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Test::More tests => 27;
use Test::Exception;
use Bio::Chado::Schema::Test;

my $schema = Bio::Chado::Schema::Test->init_schema();
my $cvterm_rs = $schema->resultset('Cv::Cvterm');

my $name = 'test cvterm_name';
my $cvname = 'test cv_name';

$schema->txn_do(sub {
    my $cvterm = $cvterm_rs->create_with({ name => $name, cv => $cvname });

    is( $cvterm->name, $name, 'cvterm_name test' );
    is( $cvterm->cv->name, $cvname, 'cv_name test');
    is( $cvterm->dbxref->accession, 'autocreated:' . $name, 'dbxref autocreated accession test' );
    is( $cvterm->dbxref->db->name, 'null', 'db name autocreated test' );

    #now add a synonym
    my $synonym='test synonym';
    my $type='exact';
    my $cvtermsynonym= $cvterm->add_synonym($synonym, { synonym_type=>$type, autocreate=>1 });

    is($cvtermsynonym->synonym, $synonym, "synonym test");
    is($cvtermsynonym->cvterm->name, $name, "synonym type test");
    is($cvtermsynonym->type->cv->name, 'synonym_type', "synonym cv name test");
    is($cvtermsynonym->type->dbxref->accession, $type, "synonym dbxref accession test");

    #try to store the same synonym - should pass since new synonyms are created after passing
    ##search_related with type_id and case-insensitive value

    my $existing_s = $cvterm->add_synonym($synonym, { synonym_type=>$type, autocreate=>1 });

    is($cvtermsynonym->cvtermsynonym_id() , $existing_s->cvtermsynonym_id(), "Existing synonym test");
    ##delete the synonym
    $cvterm->delete_synonym($synonym);

    is($cvterm->search_related('cvtermsynonyms', {synonym=>$synonym } )->count , 0, "deleted synonym test");

    #add a secondary dbxref
    my $sec_db = 'SEC';
    my $sec_acc= '1234';
    $cvterm->add_secondary_dbxref($sec_db.":".$sec_acc);

    my ($cvterm_dbxref)= $cvterm->get_secondary_dbxrefs;
    my ($re_db, $re_acc) = split(  ":" , $cvterm_dbxref);
    is($re_db, $sec_db, "secondary dbxref db name test");
    is($re_acc, $sec_acc, "secondary dbxref accession test");

    #and delete the secondary dbxref
    $cvterm->delete_secondary_dbxref($sec_db.":".$sec_acc);

    ($cvterm_dbxref)= $cvterm->get_secondary_dbxrefs;
    is($cvterm_dbxref, undef, "deleted secondary dbxref test");
    is($cvterm->search_related('cvterm_dbxrefs' )->count , 0, "deleted cvterm_dbxref test");

    #create new cvtermprop
    my $propname = "cvtermprop";
    my $value = "value 1";
    my $rank = 3;

    my $href = $cvterm->create_cvtermprops({ $propname => $value} , { autocreate => 1, allow_multiple_values => 1 , rank => $rank } );

    my $cvtermprop = $href->{$propname};
    is($cvtermprop->value(), $value, "cvtermprop value test");
    is($cvtermprop->rank() , $rank, "cvtermprop rank test");
    #

    #add another term
    my $child_name = 'test child term';
    my $child_term = $cvterm_rs->create_with({ name => $child_name, cv => $cvname });

    my $is_a = $cvterm_rs->create_with( { name => 'IS_A' , cv => 'relationship'} );
    $is_a->is_relationshiptype(1);
    $is_a->update;

    # create cvterm_relationship
    $cvterm->create_related('cvterm_relationship_objects', {
        subject_id => $child_term->cvterm_id,
        type_id => $is_a->cvterm_id,
                            } );

    # populate cvtermpath
    $child_term->create_related('cvtermpath_subjects', {
        object_id => $cvterm->cvterm_id,
        type_id => $is_a->cvterm_id,
        cv_id => $cvterm->cv_id,
        pathdistance => 1 });

    $cvterm->create_related('cvtermpath_subjects' , {
        object_id => $child_term->cvterm_id,
        type_id => $is_a->cvterm_id,
        cv_id => $cvterm->cv_id,
        pathdistance => -1 } );

    #and add a child to the child term
    my $grandchild_name = 'test grandchild term';
    my $grandchild_term = $cvterm_rs->create_with({ name => $grandchild_name, cv => $cvname });

    # create cvterm_relationship
    $child_term->create_related('cvterm_relationship_objects', {
        subject_id => $grandchild_term->cvterm_id,
        type_id => $is_a->cvterm_id,
                                } );

    # populate cvtermpath
    $grandchild_term->create_related('cvtermpath_subjects', {
        object_id => $child_term->cvterm_id,
        type_id => $is_a->cvterm_id,
        cv_id => $cvterm->cv_id,
        pathdistance => 1 });
    #########
    $grandchild_term->create_related('cvtermpath_subjects', {
        object_id => $cvterm->cvterm_id,
        type_id => $is_a->cvterm_id,
        cv_id => $cvterm->cv_id,
        pathdistance => 2 });
    #########
    $child_term->create_related('cvtermpath_subjects', {
        object_id => $grandchild_term->cvterm_id,
        type_id => $is_a->cvterm_id,
        cv_id => $cvterm->cv_id,
        pathdistance => -1 });

    #find the root.
    my $root_name = $name;
    my $root = $grandchild_term->root();
    is($root->name , $root_name , "cvterm  find root test");

    #find  children
    my $children_rs = $cvterm->children;
    my $child1 = $children_rs->first->find_related('subject', {});
    is ($child1->name , $child_name , 'cvterm find children test');
    is(scalar($children_rs->all) , 1 , 'Number of children test');

    # now using the cvtermpath
    my $direct_children = $cvterm->direct_children;
    is ($direct_children->first->name , $child_name , 'cvterm direct_children test');
    is(scalar($direct_children->all) , 1 , 'number of direct children');

    # find  parents
    my $parents_rs = $child_term->parents;
    my $parent1 = $parents_rs->first->find_related('object' , {} );
    is ($parent1->name , $name, 'cvterm find  parents test');
    is(scalar($parents_rs->all) , 1, 'Number of parents');
     # now using the cvtermpath
    my $direct_parents = $child_term->direct_parents;
    is ($direct_parents->first->name , $name , 'cvterm direct_parents test');
    is(scalar($direct_parents->all), 1, 'Number of direct parents');

    #find recursive children
    my @children = $cvterm->recursive_children->all;
    foreach my $ch (@children) { print "child =" .  $ch->name . "\n"; }
    is(scalar(@children) , 2, 'recursive_children test' );

    #find recursive parents
    my @parents = $grandchild_term->recursive_parents->all;
    foreach my $p (@parents ) { print "parent = " . $p->name . "\n"; }
    is(scalar(@parents) , 2, 'recursive_parents test');
    $schema->txn_rollback;
});



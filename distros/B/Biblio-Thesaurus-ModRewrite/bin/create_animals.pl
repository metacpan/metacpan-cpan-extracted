#!/usr/bin/perl

use Biblio::Thesaurus;
use Data::Dumper;

$obj = thesaurusNew();

$obj->addTerm('Carnivora');
$obj->addTerm('Canidae');
$obj->addTerm('Felidae');
$obj->addRelation('Carnivora','BT','Canidae');
$obj->addRelation('Carnivora','BT','Felidae');

$obj->addTerm('Panthera');
$obj->addTerm('Felis');
$obj->addRelation('Felidae','BT','Panthera');
$obj->addRelation('Felidae','BT','Felis');

$obj->addTerm('lion');
$obj->addTerm('tiger');
$obj->addRelation('Panthera','BT','lion');
$obj->addRelation('Panthera','BT','tiger');

$obj->addTerm('house_cat');
$obj->addRelation('Felis','BT','house_cat');

$obj->addTerm('Lucky');
$obj->addRelation('Lucky','is-a','house_cat');

$obj->complete;
$obj->save('animals1.iso');

$obj = thesaurusNew();
$obj->addTerm('house_cat');
$obj->addTerm('Felis');
$obj->addRelation('Felis','BT','house_cat');

$obj->addTerm('Lucky');
$obj->addRelation('Lucky','is-a','lion');

$obj->addTerm('Carnivora');
$obj->addRelation('Carnivora','BT','Felis');

$obj->addTerm('lion');
$obj->addTerm('the_lion_king');
$obj->addRelation('the_lion_king','is-a','lion');

$obj->complete;
$obj->save('animals2.iso');

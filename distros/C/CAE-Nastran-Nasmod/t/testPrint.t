use strict;
use Test;

BEGIN { plan tests => 9 }

use lib("lib");
use CAE::Nastran::Nasmod;

#------------------------------
# 1) import file and write content to a new file. import the new file
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	# entity count
	ok($model->count(), 6);

	$model->print("spl/model_roundtrip.nas");

	my $model2 = CAE::Nastran::Nasmod->new();
	$model2->importBulk("spl/model_roundtrip.nas");

	# entity count
	ok($model2->count(), 6);
	
	# extract the CQUAD4 card from model
	my @entities = $model->getEntity(["", "CQUAD4"]);
	
	# extract the CQUAD4 card from model2
	my @entities2 = $model2->getEntity(["", "CQUAD4"]);
	
	# compare the data of the first entity
	ok($entities[0]->getCol(1), $entities2[0]->getCol(1));
	ok($entities[0]->getCol(2), $entities2[0]->getCol(2));
	ok($entities[0]->getCol(3), $entities2[0]->getCol(3));
	ok($entities[0]->getCol(4), $entities2[0]->getCol(4));
	ok($entities[0]->getCol(5), $entities2[0]->getCol(5));
	ok($entities[0]->getCol(6), $entities2[0]->getCol(6));
	ok($entities[0]->getCol(7), $entities2[0]->getCol(7));

	# delete roundtripfile
	unlink("spl/model_roundtrip.nas");
}
#------------------------------


use strict;
use Test;

BEGIN { plan tests => 7 }

#use lib("../lib");
use CAE::Nastran::Nasmod;

#------------------------------
# 1) addEntity, getEntity, merge
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	# entity count
	ok($model->count(), 6);

	my $entity1 = CAE::Nastran::Nasmod::Entity->new();
	$entity1->setCol(1, "JIPEE");
	
	my $entity2 = CAE::Nastran::Nasmod::Entity->new();
	my $entity3 = CAE::Nastran::Nasmod::Entity->new();
	
	$model->addEntity($entity1);

	ok($model->count(), 7);
	
	$model->addEntity($entity2, $entity3);

	ok($model->count(), 9);
	
	my @entities = $model->getEntity(["", "JIPEE"]);
	
	ok(@entities, 1);
	
	$entity2->setCol(1, "JIPEE");
	
	ok($entity2->getRow(), 1);
	
	@entities = $model->getEntity(["", "JIPEE"]);
	
	ok(@entities, 2);
	
	my $model2 = CAE::Nastran::Nasmod->new();
	$model2->importBulk("spl/model.nas");
	
	$model->merge($model2);
	
	ok($model->count(), 15);
	
}
#------------------------------


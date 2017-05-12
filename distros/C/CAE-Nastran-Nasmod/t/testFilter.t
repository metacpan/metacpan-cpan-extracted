use strict;
use Test;

BEGIN { plan tests => 8 }

#use lib("lib");
#use lib("../lib");
use CAE::Nastran::Nasmod;

#------------------------------
# 1), 2) testing filter
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	ok($model->count(), 6);

	my @FILTER = (
		"",
		"GRID"
	);
	
	my $filteredModel = $model->filter(\@FILTER);
	ok($filteredModel->count(), 4);

}
#------------------------------

#------------------------------
# 3) testing filter
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	my @FILTER = (
		"",
		["GRID", "CQUAD4"]
	);
	
	my $filteredModel = $model->filter(\@FILTER);
	ok($filteredModel->count(), 5);

}
#------------------------------

#------------------------------
# 4) testing filter
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	my @FILTER = (
		["23456","wichtig"],
		["GRID", "CQUAD4"]
	);
	
	my $filteredModel = $model->filter(\@FILTER);
	ok($filteredModel->count(), 2);

}
#------------------------------

#------------------------------
# 5) testing filter
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	my @FILTER;
	$FILTER[0] = ["23456","wichtig"];
	$FILTER[1] = ["GRID", "CQUAD4"];

	my $filteredModel = $model->filter(\@FILTER);
	ok($filteredModel->count(), 2);

}
#------------------------------

#------------------------------
# 6) testing filter
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	my @FILTER;
	$FILTER[1] = "GRID";
	$FILTER[12] = "198";
	
	my $filteredModel = $model->filter(\@FILTER);
	ok($filteredModel->count(), 1);

}
#------------------------------

#------------------------------
# 7) testing filter
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	my @FILTER;
	$FILTER[1] = "GRID";
	$FILTER[12] = 198;
	
	my $filteredModel = $model->filter(\@FILTER);
	ok($filteredModel->count(), 1);

}
#------------------------------

#------------------------------
# 8) testing filter
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	my @FILTER;
	$FILTER[1] = "GRID";
	$FILTER[12] = [198, 0];
	
	my $filteredModel = $model->filter(\@FILTER);
	ok($filteredModel->count(), 1);

}
#------------------------------


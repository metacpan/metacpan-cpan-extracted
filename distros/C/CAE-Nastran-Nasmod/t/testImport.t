use strict;
use Test;

BEGIN { plan tests => 10 }

#use lib("../lib");
use CAE::Nastran::Nasmod;

#------------------------------
# 1) testing full import
{
	my $model = CAE::Nastran::Nasmod->new();
	$model->importBulk("spl/model.nas");
	
	# entity count
	ok($model->count(), 6);
#	$model->print();
}
#------------------------------

#------------------------------
# 2) testing import filtered cards
{
	my $model = CAE::Nastran::Nasmod->new();
	my %OPTIONS = (
		cards => ["GRID", "CTRIA"],
	);
	$model->importBulk("spl/model.nas", \%OPTIONS);
	ok($model->count(), 5);
}
#------------------------------

#------------------------------
# 3) testing import filtered cards and filtered data
{
	my $model = CAE::Nastran::Nasmod->new();
	my %OPTIONS = (
		filter => ["", ["GRID","CTRIA3"]],
	);
	$model->importBulk("spl/model.nas", \%OPTIONS);
	ok($model->count(), 5);
}
#------------------------------

#------------------------------
# 4) testing import filtered cards and filtered data
{
	my $model = CAE::Nastran::Nasmod->new();
	my %OPTIONS = (
		cards => ["GRID"],
		maxoccur => 2
	);
	$model->importBulk("spl/model.nas", \%OPTIONS);
	ok($model->count(), 2);
}
#------------------------------

#------------------------------
# 5) testing import filtered cards and filtered data
{
	my $model = CAE::Nastran::Nasmod->new();
	my %OPTIONS = (
		cards => ["GRID"],
		filter => ["", "", "4"]
	);
	$model->importBulk("spl/model.nas", \%OPTIONS);
	ok($model->count(), 1);
}
#------------------------------

#------------------------------
# 6) testing import filtered cards and filtered data
{
	my $model = CAE::Nastran::Nasmod->new();
	my %OPTIONS = (
		filter => ["234567"]
	);
	$model->importBulk("spl/model.nas", \%OPTIONS);

	ok($model->count(), 2);
}
#------------------------------

#------------------------------
# 7) testing import filtered cards and filtered data
{
	my $model = CAE::Nastran::Nasmod->new();
	my %OPTIONS = (
#		cards => ["GRID"],
		filter => ["wichtig"]
	);
	$model->importBulk("spl/model.nas", \%OPTIONS);
	ok($model->count(), 1);
}
#------------------------------

#------------------------------
# 8) testing import filtered cards and filtered data
{
	my $model = CAE::Nastran::Nasmod->new();
	my %OPTIONS = (
		cards => ["GRID"],
		filter => ["wichtig"]
	);
	$model->importBulk("spl/model.nas", \%OPTIONS);
	ok($model->count(), 0);
}
#------------------------------

#------------------------------
# 9) testing import filtered cards and filtered data
{
	my $model = CAE::Nastran::Nasmod->new();
	my %OPTIONS = (
		cards => ["GRID"],
		filter => [["wichtig", "234567"]]
	);
	$model->importBulk("spl/model.nas", \%OPTIONS);
	ok($model->count(), 1);
}
#------------------------------

#------------------------------
# 10) testing import filtered cards and filtered data
{
	my $model = CAE::Nastran::Nasmod->new();
	my %OPTIONS = (
		cards => ["GRID"],
		filter => ["", "", "", "", "", "", "", "", "", "", "", "", 198]
	);
	$model->importBulk("spl/model.nas", \%OPTIONS);
	ok($model->count(), 1);
}
#------------------------------

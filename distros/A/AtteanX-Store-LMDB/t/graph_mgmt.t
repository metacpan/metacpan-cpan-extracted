use Test::More;
use Test::Modern;
use Test::Exception;

use v5.14;
use warnings;
no warnings 'redefine';
use Attean;
use Attean::RDF;
use File::Temp;
use Data::Dumper;

my $graph	= iri('tag:kasei.us,2018:default-graph');

my $dir 	= File::Temp->newdir();
my $path	= "$dir";

subtest 'delete-quad-leave-graph' => sub {
	my $store = Attean->get_store('LMDB')->new(filename => $path, initialize => 1);
	my $model = Attean::MutableQuadModel->new( store => $store );

	my $s	= blank('s');
	my $p	= iri('http://example.org/pred');
	my $o1	= Attean::Literal->integer(1);
	my $o2	= Attean::Literal->integer(2);
	my $g	= iri('http://example.org/graph');
	
	my $q1	= quad($s, $p, $o1, $g);
	my $q2	= quad($s, $p, $o2, $g);
	
	$model->add_quad($q1);
	$model->add_quad($q2);

	is($model->size, 2);
	is(scalar(@{[ $model->get_graphs->elements ]}), 1);
	
	$model->remove_quad($q1);

	is($model->size, 1);
	is(scalar(@{[ $model->get_graphs->elements ]}), 1);
};

subtest 'delete-quad-delete-graph' => sub {
	my $store = Attean->get_store('LMDB')->new(filename => $path, initialize => 1);
	my $model = Attean::MutableQuadModel->new( store => $store );

	my $s	= blank('s');
	my $p	= iri('http://example.org/pred');
	my $o1	= Attean::Literal->integer(1);
	my $o2	= Attean::Literal->integer(2);
	my $g	= iri('http://example.org/graph');
	
	my $q1	= quad($s, $p, $o1, $g);
	my $q2	= quad($s, $p, $o2, $g);
	
	$model->add_quad($q1);
	$model->add_quad($q2);

	is($model->size, 2);
	is(scalar(@{[ $model->get_graphs->elements ]}), 1);
	
	$model->remove_quad($q1);

	is($model->size, 1);
	is(scalar(@{[ $model->get_graphs->elements ]}), 1);
	
	$model->remove_quad($q2);

	is($model->size, 0);
	is(scalar(@{[ $model->get_graphs->elements ]}), 0);
};

done_testing();

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

subtest 'create' => sub {
	my $store = Attean->get_store('LMDB')->new(filename => $path, initialize => 1);
	my $model = Attean::MutableQuadModel->new( store => $store );


	my $counter	= 0;
	my $s		= blank('s');
	my $p		= iri('http://example.org/value');
	my $g		= iri('http://example.org/graph');
	my $code	= sub {
		my $value	= int($counter++/2);
		my $o	= Attean::Literal->integer($value);
		my $q	= quad($s, $p, $o, $g);
		return if ($value >= 10);
		return $q;
	};
	my $iter	= Attean::CodeIterator->new( generator => $code, item_type => 'Attean::API::Quad' );
	$model->add_iter($iter);
	is($model->size, 10);
};

done_testing();

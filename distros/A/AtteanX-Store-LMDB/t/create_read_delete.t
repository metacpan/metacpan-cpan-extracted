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
	my $parser	= Attean->get_parser('Turtle')->new();
		$parser->handler(sub {
		my $t	= shift;
		my $q	= Attean::Quad->new($t->values, $graph);
		$model->add_quad($q);
	});
	$parser->parse_cb_from_bytes(<<'END');
@base <http://example.org/> .
@prefix :  <http://example.org/ns/> .

<s1> :p 1,2,3 .
<s2> :q "hello", "hei"@no .
<s3> :r [ :y <s1> ] .

END
	is($model->size, 7);
};

subtest 'read' => sub {
	my $store = Attean->get_store('LMDB')->new(filename => $path);
	my $model = Attean::MutableQuadModel->new( store => $store );
	is($model->size, 7);
	
	my %strings	= map { $_->value => 1 } $model->objects(iri('http://example.org/s2'))->elements;
	is_deeply(\%strings, {qw(hello 1 hei 1)});

	my $i	= $model->get_quads(undef, iri('http://example.org/ns/p'), undef, $graph);
	my @quads	= $i->elements;
	is(scalar(@quads), 3);
	foreach my $q (@quads) {
		is($q->subject->value, 'http://example.org/s1');
	}
};

subtest 'delete' => sub {
	my $store = Attean->get_store('LMDB')->new(filename => $path);
	my $model = Attean::MutableQuadModel->new( store => $store );
	
	is($model->size, 7);

	foreach my $q ($model->get_quads(undef, iri('http://example.org/ns/y'), undef, $graph)->elements) {
		$model->remove_quad($q);
	}
	is($model->size, 6);

	foreach my $q ($model->get_quads(iri('http://example.org/s2'))->elements) {
		$model->remove_quad($q);
	}
	is($model->size, 4);

	foreach my $q ($model->get_quads([iri('http://example.org/s1'), iri('http://example.org/s3')])->elements) {
		$model->remove_quad($q);
	}
	is($model->size, 0);

	my $i	= $model->get_quads();
	while (my $q = $i->next) {
		print($q->as_string . "\n");
	}
};

done_testing();

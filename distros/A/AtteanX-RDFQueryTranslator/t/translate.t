use v5.14;
use warnings;
use Test::Modern;

use AtteanX::RDFQueryTranslator;

subtest 'Project(BGP)' => sub {
	my $q	= RDF::Query->new('SELECT ?s ?o WHERE { ?s ?p ?o }');
	isa_ok($q, 'RDF::Query');
	my $t	= AtteanX::RDFQueryTranslator->new();
	my $a	= $t->translate_query($q);
	isa_ok($a, 'Attean::Algebra::Project');
	like($a->as_string, qr/Project.*BGP/s);
};

subtest 'Project(Filter(BGP))' => sub {
	my $q	= RDF::Query->new('SELECT ?s ?o WHERE { ?s ?p ?o FILTER(ISLITERAL(?o)) }');
	isa_ok($q, 'RDF::Query');
	my $t	= AtteanX::RDFQueryTranslator->new();
	my $a	= $t->translate_query($q);
	isa_ok($a, 'Attean::Algebra::Project');
	like($a->as_string, qr/Project.*Filter.*BGP/s);
	
	my ($f)	= $a->subpatterns_of_type('Attean::Algebra::Filter');
	isa_ok($f, 'Attean::Algebra::Filter');
	my $e	= $f->expression;
	isa_ok($e, 'Attean::FunctionExpression');
	is($e->operator, 'ISLITERAL');
};

done_testing();

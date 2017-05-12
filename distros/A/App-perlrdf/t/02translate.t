use App::Cmd::Tester;
use App::perlrdf;
use JSON qw(from_json);
use RDF::Trine qw(statement iri literal variable);
use Test::Exception;
use Test::More tests => 6;
use Test::RDF;

my @args = (
	translate => (map {;-i=>$_} <meta/*.pret>),
	-O        => '{format:RDFJSON}stdout:',
);
my $result = test_app 'App::perlrdf' => \@args;

is($result->stderr, '', 'nothing sent to STDERR');
is($result->error, undef, 'threw no exceptions');
is($result->exit_code, 0, 'exit code 0');

my $json_data;
lives_ok {
	$json_data = from_json( $result->stdout );
} 'JSON output to STDOUT'
or do {
	note sprintf("STDOUT: %s", $result->stdout);
	BAIL_OUT;
};

my $model = RDF::Trine::Model::->new;
$model->add_hashref($json_data);
pattern_target($model);

use RDF::Trine::Namespace qw(xsd);
my $doap = RDF::Trine::Namespace::->new('http://usefulinc.com/ns/doap#');
pattern_ok(
	statement( variable('d'), $doap->name,     literal('App-perlrdf') ),
	statement( variable('d'), $doap->license,  iri('http://dev.perl.org/licenses/') ),
	statement( variable('d'), $doap->release,  variable('r') ),
	statement( variable('r'), $doap->revision, literal('0.001', undef, $xsd->string->uri) ),
	'output contains some known data',
);


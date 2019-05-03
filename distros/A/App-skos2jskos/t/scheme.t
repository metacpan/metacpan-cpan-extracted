use v5.14;
use Test::More;
use Test::Output;
use File::Temp;
use JSON;

my $dir = File::Temp::tempdir();

my $exit;
sub run { system($^X, 'script/skos2jskos', @_); $exit = $? >> 8 }
sub slurp_json { local (@ARGV,$/) = shift; JSON->new->decode(<>) }

output_is { run('-v','t/ex/empty.ttl') } 
    "Reading RDF files\n1 triples from t/ex/empty.ttl\n",
    "RDF contains no skos:ConceptScheme\n",
    "no scheme";
ok $exit, 'error';

output_is { run('t/ex/scheme.ttl','-s','x:y') } 
    "Reading RDF files\nConverting concept scheme x:y\n",
    "Concept scheme <x:y> not found or incomplete\n",
    "not the right scheme";
ok $exit, 'error';

output_is { run('-v','t/ex/scheme.ttl','-d',$dir) } join("\n", 
        "Reading RDF files",
        "4 triples from t/ex/scheme.ttl",
        "Converting concept scheme http://example.org/",
        "Found 0 explicit top concepts",
        "Exporting JSKOS scheme",
        "$dir/scheme.json",
        "Converting concepts",
        "Exporting 0 JSKOS concepts",
        "$dir/concepts.ndjson", "" ),
    "No concepts found\n",
    "convert scheme";
ok !$exit, 'ok';

is_deeply slurp_json("$dir/scheme.json"), {
   '@context'   => 'https://gbv.github.io/jskos/context.json',
   'notation'   => ['example'],
   'prefLabel'  => { en => 'a scheme' },
   'type'       => ['http://www.w3.org/2004/02/skos/core#ConceptScheme'],
   'uri'        => 'http://example.org/',
   'definition' => { en => ['a scheme for testing'] },
}, 'converted scheme';

done_testing;

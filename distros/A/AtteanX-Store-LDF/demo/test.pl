use v5.14;
use Attean;
use Attean::RDF qw(iri blank literal);
use AtteanX::Store::LDF;

my $uri   = 'http://fragments.dbpedia.org/2014/en';
my $store = Attean->get_store('LDF')->new(start_url => $uri);

my $num  = $store->count_triples(iri('http://example.org/UNEXPECTED'));

warn "num: $num";

my $iter = $store->get_triples(iri('http://example.org/UNEXPECTED'));

while (my $triple = $iter->next) {
 say $triple->subject->ntriples_string .
   " " .
   $triple->predicate->ntriples_string . 
   " " .
   $triple->object->ntriples_string  .
   " .";
}

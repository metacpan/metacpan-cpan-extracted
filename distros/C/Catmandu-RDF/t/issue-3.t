use strict;
use warnings;
use Test::More;

use Catmandu::Exporter::RDF;

my $turtle;
my $exporter = Catmandu::Exporter::RDF->new(file => \$turtle, type => 'ttl');

my @arefs = (
    {
        "http://x.org/alice" => { "foaf_knows" => "<http://x.org/bob>" },
        "http://x.org/bob" => { "a" => "foaf_Person", }
    },
    { 
        "http://x.org/alice" => { "foaf_knows" => "<http://x.org/claire>" }, 
    }
);

$exporter->add($_) for @arefs;
$exporter->commit;

$turtle =~ s/ \./ ;/smg;
is_deeply [ sort split "\n", $turtle ], [
    '<http://x.org/alice> <http://xmlns.com/foaf/0.1/knows> <http://x.org/bob>, <http://x.org/claire> ;',
    '<http://x.org/bob> a <http://xmlns.com/foaf/0.1/Person> ;'
];
print $turtle;

done_testing;

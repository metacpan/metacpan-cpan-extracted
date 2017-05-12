use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 17;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/homol.itext";
my $stag = Data::Stag->parse($fn);

my @species = $stag->get('species_set/species');
ok(@species == 3);
ok($species[0]->get_tax_id == 10090);
foreach (@species) {
    print $_->xml;
}
@species = $stag->getnode('species_set/species');
ok(@species == 3);
ok($species[0]->get_tax_id == 10090);
my @sdata = $stag->getdata('species_set/species');
@species = map {Data::Stag->new(species=>$_)} @sdata;
ok(@species == 3);
ok($species[0]->get_tax_id == 10090);

my @symbols = $stag->get('gene_set/gene/symbol');
ok(@symbols == 2);
ok($symbols[0] eq 'HGNC');

my @snodes = $stag->getnode('gene_set/gene/symbol');
@symbols = map {$_->data} @snodes;
ok(@symbols == 2);
ok($symbols[0] eq 'HGNC');

my @gene = $stag->find_gene;
ok(@gene == 2);
map {print $_->xml} @gene;
@symbols = $stag->find_symbol;
print "S:@symbols\n";
ok(@symbols == 6);
ok("@symbols" eq "HGNC Hfe HGNC Hfe WNT3A Wnt3a");


$stag->get('species_set/species/common_name', 'foo');
my @foo = $stag->get('species_set/species/common_name');
ok(@foo == 3);
ok(!grep {$_ ne 'foo'} @foo);
$stag->get('species_set/species', Data::Stag->new(foo=>'bar'));
#print $stag->xml;
@foo = $stag->get('species_set/foo');
ok(@foo == 3);
ok(!grep {$_ ne 'bar'} @foo);

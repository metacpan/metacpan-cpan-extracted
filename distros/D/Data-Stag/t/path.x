use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 11;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/homol.itext";
my $stag = Data::Stag->new;
$stag->parse($fn);

my @species = $stag->getnode('species_set/species');
map {
    print $_->xml;
} @species;
ok(@species == 3);
my @names = sort $stag->get('species_set/species/common_name');
print "N=@names\n";
ok("@names" eq 'fruitfly house mouse human');
$stag->set('species_set/species/common_name', 'foo');
@names = $stag->get('species_set/species/common_name');
ok(!grep{$_ ne 'foo'} @names);

my ($gene) = $stag->where('gene',
                        sub {shift->get_symbol eq 'HGNC'});
$gene->set('map/cytological/chromosome', 7);
$gene->set('map/cytological/band', 'p21.3', 'p21.4');
print $gene->xml;
my @band = $gene->get('map/cytological/band');
print "band=@band\n";
ok(scalar(@band) == 2);
ok($gene->get('map/cytological/chromosome') eq '7');

$gene->setnode('map/cytological/chromosome',
               [chromosome=>8]);
print $gene->xml;

my @syms = sort $stag->findval('gene/symbol');
print "S @syms\n";

ok("@syms" eq "HGNC Hfe");
$stag->findval('gene/symbol', 'bar');
@syms = sort $stag->findval('gene/symbol');
print "S @syms\n";
ok("@syms" eq 'bar bar');

my @cyto = $stag->findnode('map/cytological');
map {print $_->xml} @cyto;
ok(@cyto == 1);
ok($cyto[0]->get_chromosome eq '8');

$stag->findnode('map/cytological',
                [foo=>[
                       [bar=>3]
                      ]]);
@maps = $stag->findnode('map/cytological');
print $stag->xml;

my @foo = $stag->findnode('map/foo');
map {print $_->xml} @foo;
ok(@foo == 1);
ok($foo[0]->get_bar eq '3');

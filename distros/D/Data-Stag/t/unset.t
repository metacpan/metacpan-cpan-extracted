use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 4;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/homol.itext";
my $stag = Data::Stag->parse($fn);

my $s = $stag->sxpr;
#print $stag->sxpr;

$stag->unset("species/tax_id");
#print $stag->sxpr;

my @species = $stag->get('species_set/species');
ok(@species == 3);
# all species/tax_id should be removed
ok(!grep {$_->get_tax_id} @species);


my @genes = $stag->get('gene_set/gene');
ok(@genes == 2);
# all species/tax_id should be removed
ok((grep {$_->get_tax_id} @genes) == 2);

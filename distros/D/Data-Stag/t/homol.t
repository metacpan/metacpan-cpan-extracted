use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 9;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/homol.itext";
my $tree = Data::Stag->new;
$tree->parse($fn);

my ($gene_set) = $tree->fn("gene_set");
my ($species_set) = $tree->fn("species_set");
$gene_set->ijoin("gene", "tax_id=tax_id", $species_set);
print $gene_set->xml;
  
my @g = $gene_set->where("gene",
                         sub {
                             shift->tm("symbol", "HGNC")
                         });

ok(@g == 1);
my $chrom = $g[0]->get("map/cytological/chromosome");
ok($chrom eq '6');
ok(grep { $_->tm("binomial", "Homo sapiens") } @g);

@g =
  $gene_set->where('gene',
                   sub { my $g = shift;
                         $g->get("symbol") =~ /^H/ &&
                           $g->findval("common_name") ne ('human')});
ok(@g == 1);
ok(grep { $_->tm("binomial", "Mus musculus") } @g);


my ($ss) = $tree->fn("similarity_set");
$ss->ijoin("pair", "symbol", $gene_set);
print $ss->xml;

sub q_gene_by_phenotype {
    my $gs = shift;
    my $ph = shift;
    $gs->where("gene", 
               sub {
                   grep {/$ph/} shift->get_phenotype
               });
}
sub q_gene_by_go {
    my $gs = shift;
    my $go = shift;
    $gs->where("gene", 
               sub {
                   grep {/$go/} shift->get_GO_term
               });
}

@g = q_gene_by_phenotype($gene_set, "Hemo");
ok(@g == 1);
@g = q_gene_by_phenotype($gene_set, "Zzz");
ok(@g == 0);
@g = q_gene_by_go($gene_set, "iron");
ok(@g == 1);
@g = q_gene_by_go($gene_set, "");
ok(@g == 2);

my @names = ();
$gene_set->iterate(sub{push(@names, shift->name)});
print "names=@names\n";

$gene_set->iterate(sub {
                       my $node= shift;
                       my $parent = shift;
                       printf "%s=>%s\n", $parent ? $parent->name : '', $node->name;
                   });


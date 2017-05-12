use Modern::Perl;

use Test::More;
use Test::Exception;
use YAML::Any;
use autodie;

use_ok( 'Bio::Protease' );

my $test_seq = <<EOL
mattsfpsmlfyfcifllfhgsmaqlfgqsstpwqssrqgglrgcrfdrlqafeplrqvr
sqagiteyfdeqneqfrctgvsvirrviepqglvlpqyhnapalvyilqgrgftgltfpg
cpatfqqqfqpfdqsqfaqgqsqsqtikdehqrvqrfkqgdvvalpagivhwcyndgdap
ivaiyvfdvnnnanqleprqkkfllagnnkfllagnnanqleprqkefllagnnkreqqs
gnnifsglsvqllsealgisqqaaqgsksndqrgrvirvsqglqflkpivsqqvpveqqv
yqpiqtqdvqatqyqvgqstqyqvgkstpyqggqssqyqagqswdqsfngleenfcslea
rknienpqhadtynpragritrlnsknfpilnivqmsatrvnlyqnailspfwninahsv
iymiqgharvqvvnnngqtvfsdilhrgqllivpqhfvvlknaeregcqyisfktnpnsm
vshiagktsilralpidvlanayrisrqearnlknnrgeefgaftpkltqtgfqsyqdie
easssavraseMVNSNQNQNGNSNGHDDDFPQDSITEPEHMRKLFIGGLDYRTTDENLKA
VMKDPRTKRSRGFGFITYSHSSMIDEAQKSRPHKIDGRVEPKRAVPRQDIDSPNAGATVK
KLFVGALKDDHDEQSIRDYFQHFGNIVDNIVIDKETGKKRGFAFVEFDDYDPVDKVVLQK
QHQLNGKMVDVKKALPKNDQQGGGGGRGGPGGRAGGNRGNMGGGNYGNQNGGGNWNNGGN
NWGNNRGNDNWGNNSFGGGGGGGGGYGGGNNSWGNNNPWDNGNGGGNFGGGGNNWNGGND
FGGYQQNYGGGPQRGGGNFNNNRMQPYQGGGGFKAGGGNQGNYGNNQGFNNGGNNRRYHE
KWGNIVDVVMVNSNQNQNGNSNGHDDDFPQDSITEPEHMRKLFIGGLDYRTTDENLKAHE
VMKDPTSTSTSTSTSTSTSTSTMIDEAQKSRPHKIDGRVEPKRAVPRQDIDSPNAGATVK
KLFVGALKDDHDEQSIRDYFQHLLLLLLLDLLLLDLLLLDLLLFVEFDDYDPVDKVVLQK
QHQLNGKMVDVKKALPKNDQQGGGGGRGGPGGRAGGNRGNMGGGNYGNQNGGGNWNNGGN
NWGNNRGNDNWGNNSFGGGGGGGGGYGGGNNSWGNNNPWDNGNGGGNFGGGGNNWNGGND
FGGYQQNYGGGPQRGGGNFNNNRMQPYQGGGGFKAGGGNQGNYGNNQGFNNGGNNRRYKW
GNIVDVV
EOL
;

$test_seq =~ s/\n//g;

open( my $fh, '<', 't/specificities.yaml' );
my $data = join('', <$fh>);
my $true_values = Load $data;

my $results;
my @products;

foreach my $specificity ( keys %{Bio::Protease->Specificities} ) {
    my $protease = Bio::Protease->new(specificity => $specificity);
    my @cleavage_sites = $protease->cleavage_sites($test_seq);
    $results->{$specificity} =  [scalar @cleavage_sites, [@cleavage_sites] ];
}

is_deeply($results, $true_values);

# Test cut
my $seq = 'AARAGQTVRFSDAAA';
my $protease = Bio::Protease->new(specificity => 'trypsin');

ok !$protease->cut($seq, 1);

is_deeply([ $protease->cut($seq, 3) ], [ 'AAR', 'AGQTVRFSDAAA' ]);
is_deeply([ $protease->cut($seq, 9) ], [ 'AARAGQTVR', 'FSDAAA' ]);

# test digest
$protease = Bio::Protease->new(specificity => 'trypsin');
@products = $protease->digest($seq);

is_deeply( [@products], ['AAR', 'AGQTVR', 'FSDAAA'] );

done_testing();

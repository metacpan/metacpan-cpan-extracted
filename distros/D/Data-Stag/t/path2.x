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

my $fn = "t/data/gene.xml";
my $stag = Data::Stag->new;
$stag->parse($fn);

my @n = $stag->findnode('transcript/gene_acc');
map {
    print $_->xml
} @n;

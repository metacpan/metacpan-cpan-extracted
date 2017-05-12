use Test::Most tests => 5, 'die';

use FindBin qw( $Bin );

use_ok 'Bio::HTS::File', qw( hts_open hts_close );

#i imagine more methods will be added to HTS::File later which is why i started this

my $test_file = $Bin . "/data/test.tsv.gz";
dies_ok { hts_open($test_file . "fefgeg") } 'missing file dies';
ok my $hts = hts_open($test_file), "file opened";
ok hts_close($hts) == 0, "file closed";

dies_ok { hts_close("not a pointer") } 'close fails on something that is not a htsFile pointer';

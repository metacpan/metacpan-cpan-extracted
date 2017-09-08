use warnings;
use 5.010;
use strict;

use IO::Handle ();

use Test::More;
use Data::Dumper;
use File::Compare qw/compare/;
use File::Temp qw/tempfile tempdir/;
use File::Spec::Functions qw/catfile rel2abs/;
use File::Copy;
use File::Path qw/make_path/;
use Bio::Gonzales::Util::Cerial;
use JSON::XS;



BEGIN { use_ok('Bio::Grid::Run::SGE::Index::FileRecordsFromNDJSON'); }

my $td = tempdir( CLEANUP => 1 );

my $jsonl_f = catfile($td, "in.jsonl");
open my $fh,'>',$jsonl_f or die "Can't open filehandle: $!";
say $fh encode_json({ key => 'eins', files => [ 't/data/S_lycopersicum_chromosomes.2.40.fa.bg.gz.fai' ]});
say $fh encode_json({ key => 'zwei', files => [ 't/data/S_lycopersicum_contigs.2.40.fa.bg.gz.fai', 't/data/S_lycopersicum_scaffolds.2.40.fa.bg.gz.fai' ]});
close $fh;

# numlines:
#     13 t/data/S_lycopersicum_chromosomes.2.40.fa.bg.gz.fai
#  26877 t/data/S_lycopersicum_contigs.2.40.fa.bg.gz.fai
#   3223 t/data/S_lycopersicum_scaffolds.2.40.fa.bg.gz.fai
#  30113 total



my $idx = Bio::Grid::Run::SGE::Index::FileRecordsFromNDJSON->new(
  'writeable' => 1,
  'idx_file'  => catfile( $td, 'test.idx' ),
  'chunk_size' => 7,
);

$idx->create([ $jsonl_f]);

diag $idx->num_elem;

diag Dumper $idx->get_elem(0);
diag Dumper $idx->get_elem(1);
diag Dumper $idx->get_elem(2);

done_testing();

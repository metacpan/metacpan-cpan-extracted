use warnings;
use Data::Dumper;
use Test::More;
use File::Temp qw/tempfile/;
use File::Compare qw/compare/;
use Bio::Gonzales::Seq::IO qw(faslurp);
use Path::Tiny;

BEGIN { use_ok( 'Bio::Gonzales::Align::IO', 'phylip_slurp', 'phylip_spew' ); }

{

  my ( $fh, $filename ) = tempfile();

  my $seqs = phylip_slurp( path("t/data/test.aln.interleaved.phylip"), 'interleaved' );
  phylip_spew( $filename, 'relaxed sequential', $seqs );
  is( compare( $filename, path('t/data/test.aln.interleaved.ref.phylip' )), 0 );

}

{
  my ( $fh, $filename ) = tempfile();

  my $seqs = faslurp(path("t/data/test.aln.fa"));
  phylip_spew( $filename, { relaxed => 0, sequential => 1 }, $seqs );
  is( compare( $filename, path('t/data/test.aln.fa.no-relaxed.ref.phylip') ), 0 );

}
{
  my ( $fh, $filename ) = tempfile();

  my $seqs = faslurp(path("t/data/test.aln.fa"));
  phylip_spew( $filename, { relaxed => 1, sequential => 1 }, $seqs );
  is( compare( $filename, path('t/data/test.aln.fa.relaxed.ref.phylip' )), 0 );

}

done_testing();

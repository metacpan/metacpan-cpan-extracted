use warnings;
use Test::More;
use Data::Dumper;
use Bio::Gonzales::Seq::IO qw(faslurp faspew);
use File::Temp qw/tempdir/;
use File::Compare qw/compare/;
use File::Spec::Functions qw/catfile/;

BEGIN {
  eval "use 5.010";
  plan skip_all => "perl 5.10 required for testing" if $@;

  use_ok( 'Bio::Gonzales::Seq::Filter', 'clean_peptide_seq' );
}

$Bio::Gonzales::Seq::IO::SEQ_FORMAT = "all_pretty";
$Bio::Gonzales::Seq::IO::WIDTH      = 80;

my $td = tempdir( CLEANUP => 1 );

my $clean_file = catfile( $td, 'pep_clean.fa' );

my $seqs = faslurp("t/Bio-Gonzales-Seq-Filter-pep_dirty.fa");
clean_peptide_seq($seqs);

faspew( $clean_file, $seqs );

is( compare( 't/Bio-Gonzales-Seq-Filter-pep_clean.fa', $clean_file ), 0, "clean error stuff" );

done_testing();

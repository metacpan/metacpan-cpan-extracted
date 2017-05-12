use warnings;
use Data::Dumper;
use Test::More;
use File::Temp qw(tempfile);


BEGIN {
  eval "use 5.010";
  plan skip_all => "perl 5.10 required for testing" if $@;

  use_ok('Bio::Gonzales::Feat::IO::BED');
  use_ok('Bio::Gonzales::Feat::IO::GFF3');
}

my ($fh, $filename) = tempfile();

{
  my $gff = Bio::Gonzales::Feat::IO::GFF3->new( file => 't/test.gff3' );

  my $bedout = Bio::Gonzales::Feat::IO::BED->new( file => $filename, mode => '>', track_name => 'test' );
  #my $bedout = Bio::Gonzales::Feat::IO::BED->new(file => \*STDERR, mode => '>');

  while ( my $z = $gff->next_feat ) { $bedout->write_feat($z); }
  #diag Dumper $gffout;

  $bedout->close;
}

done_testing();

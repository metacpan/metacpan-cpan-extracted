use warnings;
use Test::More;
use Data::Dumper;
use Bio::Gonzales::Search::IO::HMMER3;
use Bio::Gonzales::Util::Cerial;
use File::Temp qw/tempfile/;
use Bio::Gonzales::Util::File qw/slurpc/;

BEGIN { use_ok('Bio::Gonzales::Domain::Group'); }

{
  my $q = yslurp("t/data/starch_search_ioannis.hmmer3.reference_result.yml");
  $q->{test} = $q->{'Alpha-amylase#PF00128.19'};

  my $l = Bio::Gonzales::Domain::Group->domain_list($q);

  # Alpha-amylase#PF00128.19
  $l
    = Bio::Gonzales::Domain::Group->new( search_result => $q, required_domains => [ [ 'PF00128.19', 't' ] ] );
  is_deeply( $l->required_domains, [ [ 'Alpha-amylase#PF00128.19', 'test' ] ] );
}

{
  my $q = Bio::Gonzales::Search::IO::HMMER3->new( file => "t/data/HMMSearch_Speruvianum.result" )->parse;
  is_deeply( [ sort @{Bio::Gonzales::Domain::Group->domain_list($q)}],
    [ 'Helicase_C#PF00271.24', 'SM00487_DEXDc', 'SM00490_HELICc',  'SNF2_N#PF00176.16',  ] );

  my $l = Bio::Gonzales::Domain::Group->new( search_result => $q, required_domains => [ [qr/Helic/i] ] );
  is_deeply( [ sort @{$l->required_domains->[0]}], [  'Helicase_C#PF00271.24', 'SM00490_HELICc'  ] );

}

{
  my $q = Bio::Gonzales::Search::IO::HMMER3->new( file => "t/data/HMMSearch_Speruvianum.result" )->parse;

  my @only_snf2n
    = ( 'pSolyc10g011940.1.1;', 'pSolyc04g056400.2.1;', 'pSolyc03g095680.1.1;', 'pSolyc10g049740.1.1;' );

  my $l = Bio::Gonzales::Domain::Group->new(
    search_result     => $q,
    required_domains  => [ [qr/SNF2_N/] ],
    forbidden_domains => [ [qr/heli/i] ]
  );
  is( scalar @{ $l->filter_ids }, 4 );
  my %map = map { $_ => 1 } @only_snf2n;

  my $ids = $l->filter_ids;
  for my $id (@$ids) {
    ok( exists( $map{$id} ), $id );
  }
}

{
  my $q = Bio::Gonzales::Search::IO::HMMER3->new( file => "t/data/HMMSearch_Speruvianum.result" )->parse;

  my $l = Bio::Gonzales::Domain::Group->new(
    search_result    => $q,
    required_domains => [ ['SNF2_N#PF00176.16'], [ 'SM00490_HELICc', 'Helicase_C#PF00271.24' ] ],
  );
  is( scalar @{ $l->filter_ids }, 37 );

  ( undef, my $gff_f ) = tempfile();
  #$gff_f = "/tmp/test.gff3";
  $l->to_gff($gff_f);
  #jspew("/tmp/test.json", $l->filter_hits);

  my @ref_lines = slurpc("t/data/HMMSearch_Speruvianum.gff");
  my @out_lines = slurpc($gff_f);

  for (@ref_lines) { s/ID=hit_\d+//; }
  for (@out_lines) { s/ID=hit_\d+//; }

  #is_deeply( [ sort @out_lines ], [ sort @ref_lines ] );
}

done_testing();

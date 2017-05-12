use warnings;
use Data::Dumper;
use Test::More;
use Bio::Gonzales::Util::Cerial;

BEGIN {
  eval "use 5.010";
  plan skip_all => "perl 5.10 required for testing" if $@;

  use_ok('Bio::Gonzales::Search::IO::HMMER3');
}

{
  my $h = Bio::Gonzales::Search::IO::HMMER3->new( file => "t/Bio-Gonzales-Search-IO-HMMER3_no-hits.result" );

  is_deeply( $h->parse, { 'nb-arc_plants' => {} }, 'empty hmm3 search result' );
}

my $h = Bio::Gonzales::Search::IO::HMMER3->new( file => "t/data/starch_search_ioannis.hmmer3.result" );

#yspew("t/data/starch_search_ioannis.hmmer3.reference_result.yml", $h->parse);
is_deeply(
  $h->parse,
  yslurp("t/data/starch_search_ioannis.hmmer3.reference_result.yml"),
  "starch error w/ alignments"
);

done_testing();


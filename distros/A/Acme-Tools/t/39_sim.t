# make && perl -Iblib/lib t/39_sim.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests    => 21;
eval 'require String::Similarity';
map ok(1,'skip -- String::Similarity is missing'),1..21 and exit if $@;
for(map[map trim,split/\|/],split/\n/,<<""){
  Humphrey DeForest Bogart | Bogart Humphrey DeForest | 0.71    |  1.00
  Humphrey Bogart          | Humphrey Gump Bogart     | 0.86    |  1.00
  Humphrey deforest Bogart | Bogart DeForest          | 0.41    |  1.00
  Humfrey DeForest Boghart | BOGART HUMPHREY          | 0.05    |  0.87
  Humphrey                 | Bogart Humphrey          | 0.70    |  1.00
  Humfrey Deforest Boghart | BOGART D. HUMFREY        | 0.15    |  0.78
  Presley, Elvis Aaron     | Elvis Presley            | 0.42424 |  1.00

  my($s1,$s2,$sim,$sim_perm)=@$_;
  ok( $sim < $sim_perm );
  is_approx(sim($s1,$s2), $sim);
  is_approx(sim_perm($s1,$s2), $sim_perm);
}
sub is_approx { my($got,$exp,$msg)=@_; my $margin=30/31; between($got/$exp, $margin,1/$margin) ? ok(1,$msg) : is($got,$exp,$msg) }

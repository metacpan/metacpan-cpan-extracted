use strict;
use warnings;
use Test::More skip_all => 'no pod coverage checks';

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
  if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
  if $@;
#all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::Moose'});
#all_pod_coverage_ok();

plan skip_all => "not testing pod coverage" if($ENV{NO_POD_COVERAGE});

my @modules = all_modules();
plan tests => scalar @modules;

my %trustme = (
  'Bio::Grid::Run::SGE::Iterator::Consecutive' => [
    qw(
      cur_comb
      next_comb
      num_comb
      peek_comb_idx
      )
  ],
  'Bio::Grid::Run::SGE::Index::FileList' => [qw(BUILD)],
  'Bio::Grid::Run::SGE::Role::Iterable' => [qw(BUILD)],
  'Bio::Grid::Run::SGE::Master'    => => [qw(BUILD)],
  'Bio::Grid::Run::SGE::Worker'    => => [qw(BUILD)],
);

for my $module ( sort @modules ) {
  my $trustme = [];
  if ( $trustme{$module} ) {
    my $methods = join '|', @{ $trustme{$module} };
    $trustme = [qr/^(?:$methods)$/];
  }
  pod_coverage_ok( $module, { trustme => $trustme }, "Pod coverage for $module" );
}

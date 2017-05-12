use strict;
use warnings;

use ExtUtils::testlib;
use FindBin;
use List::MoreUtils qw/zip/;
use Test::More;
use Test::Exception;

use lib $FindBin::Bin; # for Algorithm::NaiveKmeans

use Algorithm::KernelKMeans::PP;
use Algorithm::KernelKMeans::Util qw/generate_polynominal_kernel/;
use Algorithm::NaiveKMeans;

diag 'This test may take some minutes';

open my $vectors , '<', "$FindBin::Bin/vectors.txt" or die $!;
my @vertices = map {
  my @vals = split /\s+/;
  my @keys = 0 .. $#vals;
  +{ zip @keys, @vals };
} <$vectors>;
open my $kmat, '<', "$FindBin::Bin/kernels.txt" or die $!;
my @kernel_matrix = map { [ split /\s+/ ] } <$kmat>;

dies_ok {
  Algorithm::KernelKMeans::PP->new;
} '"vertices" is required';

lives_ok {
  Algorithm::KernelKMeans::PP->new(vertices => \@vertices);
} 'Default kernel is available';

lives_ok {
  Algorithm::KernelKMeans::PP->new(
    vertices => \@vertices,
    weights => [0 .. $#vertices]
  );
} '"vertices" and "weights" must be same size';

dies_ok {
  Algorithm::KernelKMeans::XS->new(vertices => []);
} '"vertices" must not be empty';

dies_ok {
  Algorithm::KernelKMeans::PP->new(
    vertices => \@vertices,
    weights => [1, 1, 1]
  );
} '"vertices" and "weights" must be same size';

lives_ok {
  Algorithm::KernelKMeans::PP->new(
    vertices => \@vertices,
    kernel => generate_polynominal_kernel(1, 2)
  );
} 'Kernel function can be set';

lives_ok {
  Algorithm::KernelKMeans::PP->new(
    vertices => \@vertices,
    kernel_matrix => \@kernel_matrix
  );
} 'Kernel matrix can be speficied manually';

dies_ok {
  Algorithm::KernelKMeans::PP->new(
    vertices => \@vertices,
    kernel_matrix => [ @kernel_matrix[0 .. 31] ]
  );
} 'Kernel matrix must be bigger than NxN (N is number of vertices)';

sub sort_cluster {
  [ sort {
    $a->{0} <=> $b->{0} or $a->{1} <=> $b->{1} or $a->{2} <=> $b->{2}
  } @{ +shift } ]
}

{
  my $kkm = Algorithm::KernelKMeans::PP->new(
    vertices => \@vertices,
    kernel => generate_polynominal_kernel(0, 1) # just inner product
  );
  my $kkm_clusters = $kkm->run(k => 6, shuffle => 0);
  my @kkm_clusters = map { sort_cluster $_ } @$kkm_clusters;

  my $nkm = Algorithm::NaiveKMeans->new(vertices => \@vertices);
  my $nkm_clusters = $nkm->run(k => 6, shuffle => 0);
  my @nkm_clusters = map { sort_cluster $_ } @$nkm_clusters;

  is_deeply \@kkm_clusters, \@nkm_clusters,
    'WKKM with uniform weights and identity kernel is equivalant to naive KM';
}

{
  my $kkm = Algorithm::KernelKMeans::PP->new(
    vertices => \@vertices,
    kernel => generate_polynominal_kernel(1, 2)
  );

  dies_ok {
    $kkm->run;
  } '"k" is required';

  dies_ok {
    $kkm->run(k =>  6, k_min => 10);
  } '"k_min" must be less than or equal to "k"';

  dies_ok {
    $kkm->run(k => 6, foo => 'bar');
  } 'Unkown parameter should be error';

  my @clusters1 = map { sort_cluster $_ } @{ $kkm->run(k => 6, shuffle => 0) };
  my @clusters2 = map { sort_cluster $_ } @{ $kkm->run(k => 6, shuffle => 0) };
  is_deeply \@clusters1, \@clusters2,
    'WKKM with same initial cluster is deterministic';
}

done_testing;

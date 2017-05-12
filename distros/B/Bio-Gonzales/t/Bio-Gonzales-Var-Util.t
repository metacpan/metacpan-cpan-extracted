use warnings;
use 5.010;
use strict;

use Test::More;
use Data::Dumper;
use File::Temp qw/tempfile tempdir/;
use File::Spec::Functions;
use File::Copy;
use File::Path qw/make_path/;

BEGIN { use_ok('Bio::Gonzales::Var::Util', 'renumber_genotypes'); }

my @genotypes = qw(0/0:10 1/1:11 2/2:22:33:44);
my @map = (0,3,4,5);
diag Dumper \@genotypes;
diag Dumper renumber_genotypes(\@map,\@genotypes);
diag Dumper \@genotypes;

done_testing();

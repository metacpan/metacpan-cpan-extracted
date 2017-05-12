#== TESTS =====================================================================

use strict;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @PODs = qw(
	      lib/AI/NeuralNet/FastSOM.pm
	      lib/AI/NeuralNet/FastSOM/Rect.pm
	      lib/AI/NeuralNet/FastSOM/Hexa.pm
	      lib/AI/NeuralNet/FastSOM/Torus.pm
              );
plan tests => scalar @PODs;

map {
    pod_file_ok ( $_, "$_ pod ok" )
    } @PODs;

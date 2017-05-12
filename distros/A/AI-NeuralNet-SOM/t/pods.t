#== TESTS =====================================================================

use strict;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

my @PODs = qw(
	      lib/AI/NeuralNet/SOM.pm
	      lib/AI/NeuralNet/SOM/Rect.pm
	      lib/AI/NeuralNet/SOM/Hexa.pm
	      lib/AI/NeuralNet/SOM/Torus.pm
              );
plan tests => scalar @PODs;

map {
    pod_file_ok ( $_, "$_ pod ok" )
    } @PODs;

use strict;
use warnings;
use Test::More;

eval { require Test::DistManifest; 1 }
    or plan skip_all => 'Test::DistManifest required';

Test::DistManifest::manifest_ok();

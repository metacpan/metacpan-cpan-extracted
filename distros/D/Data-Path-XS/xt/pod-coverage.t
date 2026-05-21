use strict;
use warnings;
use Test::More;

eval { require Test::Pod::Coverage; Test::Pod::Coverage->VERSION(1.08); 1 }
    or plan skip_all => 'Test::Pod::Coverage 1.08+ required';
eval { require Pod::Coverage; Pod::Coverage->VERSION(0.18); 1 }
    or plan skip_all => 'Pod::Coverage 0.18+ required';

# We document every public function under its own =head2 heading.
# import/unimport are infrastructure and intentionally undocumented;
# Data::Path::XS::Compiled is an opaque object class with only DESTROY.
Test::Pod::Coverage::pod_coverage_ok(
    'Data::Path::XS',
    {
        also_private => [ qr/^(import|unimport)$/ ],
        trustme      => [],
    },
    'Data::Path::XS POD covers every public function',
);

done_testing;

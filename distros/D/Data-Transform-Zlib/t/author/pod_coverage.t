use Test::Pod::Coverage tests => 1;
pod_coverage_ok( 'Data::Transform::Zlib', {
                coverage_class => 'Pod::Coverage::CountParents',
                trustme => [qw(BUFFER DEFLATER DEFLATE_OPTIONS INFLATER INFLATE_OPTIONS)],
        }
);

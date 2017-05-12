use Test::Pod::Coverage tests => 1;
pod_coverage_ok(
    'Attribute::Default',
    { trustme => [qr/^(Default|Defaults|exsub)$/] },
    'Attribute::Default is covered'
);

eval 'require Test::Perl::Metrics::Lite';
if ($@) {
    eval "use Test::More";
    Test::More::plan(
        skip_all => 'Test::Perl::Metrics::Lite required for testing code metrics.'
    );
}
else {
    Test::Perl::Metrics::Lite->import(
        -mccabe_complexity => 20,
        -loc => 80,
        -except_dir  => [
        ],
        -except_file => [
        ],
    );
    all_metrics_ok();
}
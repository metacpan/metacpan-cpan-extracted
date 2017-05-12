use Test::More;
BEGIN {
    if (! $ENV{TEST_POD} ) {
        plan(skip_all => "TEST_POD not specified");
    } else {
        eval "use Test::Pod::Coverage 1.08";
        plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;
    }
}

my @modules = grep { ! /PP/ } all_modules();
plan tests => scalar @modules;

my %trustme =
    ( 'DateTimeX::Lite'           =>
      { trustme => [ qr/0$/, qr/^STORABLE/, 'utc_year',
                     'timegm',
                     # deprecated methods
                     'DefaultLanguage', 'era', 'language',
                   ] },
      'DateTimeX::Lite::Helpers'  =>
      { trustme => [ qr/./ ] },
      'DateTimeX::Lite::Infinite' =>
      { trustme => [ qr/^STORABLE/, qr/^set/, qr/^is_(?:in)?finite/,
                     'truncate' ] },
    );


for my $mod ( sort @modules )
{
    pod_coverage_ok( $mod, $trustme{$mod} || {}, $mod );
}

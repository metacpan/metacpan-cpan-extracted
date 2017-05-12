use Test::More;
plan skip_all => "Test::Dependencies is not installed." unless eval { require Test::Dependencies; 1 };
Test::Dependencies->import(
    exclude => [qw( Test::Dependencies DBIx::Simple::Inject )],
    style => 'light',
);
ok_dependencies();

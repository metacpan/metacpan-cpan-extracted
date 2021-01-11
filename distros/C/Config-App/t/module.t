use Test2::V0;
use Test::Warn;
use Config::App;

my $obj;
ok( $obj = Config::App->new, 'Config::App->new()' );
is( ref $obj, 'Config::App', 'ref $object' );

ok( @{ $obj->get( qw( config_app includes ) ) } == 2, 'new() included 2 files' );
ok( length( $obj->get( qw( config_app root_dir ) ) ) > 0, 'root_dir established' );
is( $obj->get('answer'), 2048, 'Included file overrides correctly' );

ok( $obj = Config::App->new( 'config/alt.yaml', 1 ), 'Config::App->new( "alt.yaml", 1 )' );
is( $obj->get('answer'), 45, 'Alt file with no include works correctly' );

ok( $obj = Config::App->new( 'config/app_optional.yaml', 1 ), 'Config::App->new( "app_optional.yaml", 1 )' );
is( $obj->get('answer'), 2048, 'Optional existing included file overrides correctly' );

ok(
    $obj = Config::App->new( 'config/app_optional_missing.yaml', 1 ),
    'Config::App->new( "app_optional_missing.yaml", 1 )',
);
is( $obj->get('answer'), 42, 'Optional non-existing included file silently skipped' );

my $env = $ENV{CONFIGAPPINIT};
$ENV{CONFIGAPPINIT} = 'config/alt.yaml';
ok( $obj = Config::App->new( undef, 1 ), 'Config::App->new( undef, 1 )' );
is( $obj->get('answer'), 45, 'Alt file with no include works correctly' );
$ENV{CONFIGAPPINIT} = $env;

$env = $ENV{CONFIGAPPENV};
$ENV{CONFIGAPPENV} = 'test';
ok( $obj = Config::App->new( 'config/alt.yaml', 1 ), 'Config::App->new( "alt.yaml", 1 )' );
is( $obj->get('env'), 'works', 'Setting CONFIGAPPENV works' );
$ENV{CONFIGAPPENV} = $env;

$obj->put( 'answer', 54321 );
is( $obj->get('answer'), 54321, 'put() works as expected' );

my $data = $obj->conf({ nested => { something => { 'else' => 'better' } } });
delete $data->{config_app};
is(
    $data,
    {
        answer => 54321,
        nested => {
            something => {
                'else' => 'better'
            },
        },
        env => 'works'
    },
    'conf() works as expected',
);

$obj = Config::App->new( 'config/app.yaml', 1 );
my $nested = $obj->get('nested');
$nested->{something}{else} = 'different';

is(
    $obj->get('nested'),
    {
        something => {
            else => 'good',
        },
    },
    'Returned data is a copy; not a ref to original',
);

warning_like(
    sub { $obj = Config::App->new( 'config/recursion_1.yaml', 1 ) },
    [qr/^Configuration include recursion encountered/],
    'Recursion of includes in singleton mode',
);

done_testing;

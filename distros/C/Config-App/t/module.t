use strict;
use warnings;

use Test::Most;

use constant MODULE => 'Config::App';

BEGIN { use_ok(MODULE); }
require_ok(MODULE);

my $obj;
ok( $obj = MODULE->new, MODULE . '->new()' );
is( ref $obj, MODULE, 'ref $object' );

ok( @{ $obj->get( qw( config_app includes ) ) } == 2, 'new() included 2 files' );
ok( length( $obj->get( qw( config_app root_dir ) ) ) > 0, 'root_dir established' );
is( $obj->get('answer'), 2048, 'Included file overrides correctly' );

ok( $obj = MODULE->new( 'config/alt.yaml', 1 ), MODULE . '->new( "alt.yaml", 1 )' );
is( $obj->get('answer'), 45, 'Alt file with no include works correctly' );

ok( $obj = MODULE->new( 'config/app_optional.yaml', 1 ), MODULE . '->new( "app_optional.yaml", 1 )' );
is( $obj->get('answer'), 2048, 'Optional existing included file overrides correctly' );

ok( $obj = MODULE->new( 'config/app_optional_missing.yaml', 1 ), MODULE . '->new( "app_optional_missing.yaml", 1 )' );
is( $obj->get('answer'), 42, 'Optional non-existing included file silently skipped' );

my $env = $ENV{CONFIGAPPINIT};
$ENV{CONFIGAPPINIT} = 'config/alt.yaml';
ok( $obj = MODULE->new( undef, 1 ), MODULE . '->new( undef, 1 )' );
is( $obj->get('answer'), 45, 'Alt file with no include works correctly' );
$ENV{CONFIGAPPINIT} = $env;

$env = $ENV{CONFIGAPPENV};
$ENV{CONFIGAPPENV} = 'test';
ok( $obj = MODULE->new( 'config/alt.yaml', 1 ), MODULE . '->new( "alt.yaml", 1 )' );
is( $obj->get('env'), 'works', 'Setting CONFIGAPPENV works' );
$ENV{CONFIGAPPENV} = $env;

$obj->put( 'answer', 54321 );
is( $obj->get('answer'), 54321, 'put() works as expected' );

my $data = $obj->conf({ nested => { something => { 'else' => 'better' } } });
delete $data->{config_app};
is_deeply(
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

$obj = MODULE->new( 'config/app.yaml', 1 );
my $nested = $obj->get('nested');
$nested->{something}{else} = 'different';

is_deeply(
    $obj->get('nested'),
    {
        something => {
            else => 'good',
        },
    },
    'Returned data is a copy; not a ref to original',
);

warning_like(
    sub { $obj = MODULE->new( 'config/recursion_1.yaml', 1 ) },
    [qr/^Configuration include recursion encountered/],
    'Recursion of includes in singleton mode',
);

done_testing;

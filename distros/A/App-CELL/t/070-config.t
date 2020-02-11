#!perl

#
# t/070-config.t
#
# Run Config.pm through its paces
#

use 5.012;
use strict;
use warnings;
use App::CELL::Config qw( $meta $core $site );
use App::CELL::Load;
use App::CELL::Log qw( $log );
use App::CELL::Test;
#use App::CELL::Test::LogToFile;
use Data::Dumper;
use Test::More;
use Test::Warnings;

my $status;
$log->init( ident => 'CELLtest', debug_mode => 1 );
$log->info("-------------------------------------------------------");
$log->info("---                  070-config.t                   ---");
$log->info("-------------------------------------------------------");

#
# META
#

$status = $meta->CELL_META_TEST_PARAM_BLOOEY;
ok( ! defined($status), "Still no blooey" );
ok( ! $meta->exists( 'CELL_META_TEST_PARAM_BLOOEY' ) );

$status = $meta->set( 'CELL_META_TEST_PARAM_BLOOEY', 'Blooey' );
ok( $status->ok, "Blooey create succeeded" );
ok( $meta->exists( 'CELL_META_TEST_PARAM_BLOOEY' ) );

# 'exists' returns undef on failure
$status = exists $App::CELL::Config::meta->{ 'CELL_META_TEST_PARAM_BLOOEY' };
ok( defined( $status ), "Blooey exists after its creation" );

$status = $meta->CELL_META_TEST_PARAM_BLOOEY;
is( $status, "Blooey", "Blooey has the right value via get_param" );

$status = App::CELL::Load::init( verbose => 1 );
is( $status->level, "WARN", "Load without sitedir gives warning" );

# 'exists' returns undef on failure
$status = $meta->CELL_META_UNIT_TESTING;
ok( defined( $status ), "Meta unit testing param exists" );

my $value = $App::CELL::Config::meta->{ 'CELL_META_UNIT_TESTING' }->{'Value'};
is( ref( $value ), "ARRAY", "Meta unit testing param is an array reference" );
is_deeply($value, [ 1, 2, 3, 'a', 'b', 'c' ], "Meta unit testing param, obtained by cheating, has expected value" );

my $result = $meta->CELL_META_UNIT_TESTING;
is_deeply( $result, [ 1, 2, 3, 'a', 'b', 'c' ], "Meta unit testing param, obtained via get_param, has expected value" );

$status = $meta->set( 'CELL_META_UNIT_TESTING', "different foo" );
#diag( "\$status level is " . $status->level . ", code " . $status->code );
ok( $status->ok, "set_meta says OK" );

$result = undef;
$result = $meta->CELL_META_UNIT_TESTING;
is( $result, "different foo", "set_meta really changed the value" );
# (should also test that this triggers a log message !)

# Bug #51
# https://sourceforge.net/p/perl-cell/tickets/51/
$result = undef;
$result = $meta->CELL_CORE_UNIT_TESTING;
#diag( "Use meta to access core param: " . Dumper( $result ) );
ok( ! defined( $result ), 'Cannot use $meta to access a core param' );
$result = $meta->CELL_SITE_UNIT_TESTING;
ok( ! defined( $result ), 'Cannot use $meta to access a site param' );
$result = $meta->get_param('CELL_SITE_UNIT_TESTING');
ok( ! defined( $result ), 'Cannot use $meta to access a site param' );
$result = $meta->get_param_meta('CELL_SITE_UNIT_TESTING');
ok( ! defined( $result ), 'Cannot use $meta to access a site param' );

#
# CORE
#

# 'exists' returns undef on failure
$status = exists $App::CELL::Config::core->{ 'CELL_CORE_UNIT_TESTING' };
ok( defined( $status ), "Core unit testing param exists" );

$value = $App::CELL::Config::core->{ 'CELL_CORE_UNIT_TESTING' }->{'Value'};
is( ref( $value ), "ARRAY", "Core unit testing param is an array reference" );
is_deeply( $value, [ 'nothing special' ], "Core unit testing param, obtained by cheating, has expected value" );

$result = $core->CELL_CORE_UNIT_TESTING;
is_deeply( $result, [ 'nothing special' ], "Core unit testing param, obtained via get_param, has expected value" );

$status = $core->set( 'CELL_CORE_UNIT_TESTING', "different bar" );
ok( $status->level eq 'ERR', "Attempt to set existing core param triggered ERR" );

my $new_result = $core->CELL_CORE_UNIT_TESTING;
isnt( $new_result, "different bar", "set_core did not change the value" );
is( $new_result, $result, "the value stayed the same" );

#
# SITE
#

# 'exists' returns undef on failure
$status = exists $App::CELL::Config::site->{ 'CELL_SITE_UNIT_TESTING' };
ok( defined( $status ), "Site unit testing param exists" );

$value = $App::CELL::Config::site->{ 'CELL_SITE_UNIT_TESTING' }->{'Value'};
is( ref( $value ), "ARRAY", "Site unit testing param is an array reference" );

is_deeply( $value, [ 'Om mane padme hum' ], "Site unit testing param, obtained by cheating, has expected value" );

$result = $site->CELL_SITE_UNIT_TESTING;
is_deeply( $result, [ 'Om mane padme hum' ], "Site unit testing param, obtained via get_param, has expected value" );

$status = $site->set( 'CELL_SITE_UNIT_TESTING', "different baz" );
ok( $status->level eq 'ERR', "Attempt to set existing site param triggered ERR" );

$new_result = $site->CELL_SITE_UNIT_TESTING;
isnt( $new_result, "different baz", "set_site did not change the value" );
is( $new_result, $result, "the value stayed the same" );

done_testing;

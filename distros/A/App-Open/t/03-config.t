#===============================================================================
#
#         FILE:  03-config.t
#
#  DESCRIPTION:  Tests App::Open::Config
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  06/02/2008 03:44:57 AM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

use constant CLASS => 'App::Open::Config';

BEGIN {
    use_ok(CLASS);
}

sub test_backend_order {
    my ( $backend_order, $package_list ) = @_;

    is_deeply( [ map { ref($_) } @{$backend_order} ],
        $package_list, 'testing backend_order' );
}

my $tmp;
my $config_file;

#
# XXX A lot of these tests actually tests load_config() indirectly.
# XXX There's no reason to duplicate these tests.
#

can_ok( CLASS, "new" );

# no config = empty hash
lives_ok { $tmp = CLASS->new };

isa_ok( $tmp, CLASS );
is_deeply( $tmp->{config}, {} );
ok( defined( $tmp->config_file ) && !length( $tmp->config_file ),
    'config_file should be an empty string' );

$config_file = "t/resource/configs/good_load.yaml";

# this is just a delimiter that tells it the root DS is a hash
lives_ok { $tmp = CLASS->new($config_file) };

isa_ok( $tmp, CLASS );
is_deeply( $tmp->{config}, {} );
is( $tmp->{config_file}, $config_file );

$config_file = "t/resource/configs/good_load2.yaml";

# YAML::Syck throws an unsightly warning trying to process this empty file
lives_ok { local $^W = 0; $tmp = CLASS->new($config_file) };

isa_ok( $tmp, CLASS );
is_deeply( $tmp->{config}, {} );
is( $tmp->{config_file}, $config_file );

# an array
throws_ok { $tmp = CLASS->new("t/resource/configs/bad_load.yaml") }
    qr/INVALID_CONFIGURATION/;

# garbage to YAML::Syck
throws_ok { $tmp = CLASS->new("t/resource/configs/bad_load2.yaml") }
    qr/INVALID_CONFIGURATION/;

#
# load_backend() tests
#

my $test_backend = "App::Open::Backend::Dummy";

lives_ok { $tmp = CLASS->new };

ok( !$test_backend->can('lookup_file'), "$test_backend shouldn't be loaded yet" );

lives_ok { $tmp->load_backend($test_backend) } 'loads with full package name';
test_backend_order( $tmp->backend_order, [$test_backend] );

can_ok( $test_backend, "lookup_file" );

lives_ok { $tmp->load_backend("Dummy") } 'loads with abbrev package name';

#
# FIXME should probably come up with a good way of uniqing this stuff.
#
test_backend_order( $tmp->backend_order, [ $test_backend, $test_backend ] );

#
# load_backends() tests
#

lives_ok { $tmp = CLASS->new };
lives_ok { $tmp->load_backends($test_backend) } 'argument list: 1 backend';
test_backend_order( $tmp->backend_order, [$test_backend] );
lives_ok { $tmp->load_backends("Dummy") } 'argument list: abbrev backend';

#
# FIXME should probably come up with a good way of uniqing this stuff.
#
test_backend_order( $tmp->backend_order, [ $test_backend, $test_backend ] );

lives_ok { $tmp = CLASS->new };
lives_ok { $tmp->load_backends( $test_backend, "Dummy" ) }
    'argument list: 2 backends, one abbrev, one not';

lives_ok { $tmp = CLASS->new("t/resource/configs/load_backend.yaml") }
    "construct with load_backend.yaml";
lives_ok { $tmp->load_backends } 'no arguments';
test_backend_order( $tmp->backend_order, [$test_backend] );

lives_ok { $tmp = CLASS->new("t/resource/configs/load_backend2.yaml") }
    "construct with load_backend2.yaml";
lives_ok { $tmp->load_backends } 'no arguments';
test_backend_order( $tmp->backend_order, [ $test_backend, $test_backend ] );

lives_ok { $tmp = CLASS->new("t/resource/configs/load_backend.yaml") }
    "construct with load_backend.yaml";
lives_ok { $tmp->load_backends($test_backend) } 'argument + config';
test_backend_order( $tmp->backend_order, [ $test_backend, $test_backend ] );

lives_ok { $tmp = CLASS->new("t/resource/configs/load_backend2.yaml") }
    "construct with load_backend2.yaml";
lives_ok { $tmp->load_backends($test_backend) } 'argument + config';
test_backend_order( $tmp->backend_order,
    [ $test_backend, $test_backend, $test_backend ] );

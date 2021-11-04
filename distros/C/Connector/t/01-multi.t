# Tests for Connector::Multi
#

use strict;
use warnings;
use English;

use Test::More tests => 49;
use Path::Class;
use DateTime;


use Log::Log4perl;
Log::Log4perl->easy_init( { level   => 'WARN' } );

my ($base, $conn);

BEGIN {
    use_ok( 'Config::Versioned' );
    use_ok( 'Connector::Multi' );
    use_ok( 'Connector::Proxy::YAML' );
    use_ok( 'Connector::Proxy::Config::Versioned' );
}

require_ok( 'Config::Versioned' );
require_ok( 'Connector::Multi' );
require_ok( 'Connector::Proxy::YAML' );
require_ok( 'Connector::Proxy::Config::Versioned' );

# The Connector::Multi uses Connector::Proxy::Config::Versioned, which
# must first be initialized with our test data.
my @test_data = (
    {
        dbpath => 't/config/01-multi-flat.git',
        filename => '01-multi-flat.conf',
        path => [ qw( t/config ) ],
    },
    {
        dbpath => 't/config/01-multi-sym1.git',
        filename => '01-multi-sym1.conf',
        path => [ qw( t/config ) ],
    },
);

foreach my $data ( @test_data ) {
    dir($data->{dbpath})->rmtree;
    my $cv = Config::Versioned->new(
        {
            dbpath => $data->{dbpath},
            autocreate => 1,
            filename => $data->{filename},
            path => $data->{path},
            commit_time => $data->{commit_time} ||
                DateTime->from_epoch( epoch => 1240341682 ),
            author_name => $data->{author_name} || 'Test User',
            author_mail => $data->{author_mail} || 'test@example.com',
        }
    ) or die "Error creating Config::Versioned: $@";
}


###########################################################################
#my $base = Connector::Proxy::Config::Versioned->new({
#	LOCATION  => $test_data[0]->{dbpath},
#});
#
#is($base->get('smartcards.tokens.token_1.status'), 'ACTIVATED',
#    'check base connector (1)');
#is($base->get('smartcards.owners.joe.tokenid'), 'token_1',
#    'check base connector (2)');
#is($base->get('smartcards.tokens.token_1.nonexistent'), undef,
#    'check base connector (3)');

$conn = Connector::Multi->new( {
    BASECONNECTOR => 'Connector::Proxy::Config::Versioned',
    LOCATION => $test_data[0]->{dbpath},
    });


is($conn->get('smartcards.tokens.token_1.status'), 'ACTIVATED',
    'multi with simple config (1)');
is($conn->get('smartcards.owners.joe.tokenid'), 'token_1',
    'multi with simple config (2)');
is($conn->get('smartcards.tokens.token_1.nonexistent'), undef, 'multi with simple config (3)');

# Reuse $base and $conn to ensure we don't accidentally test previous
# connectors.
$base = Connector::Proxy::Config::Versioned->new({
    LOCATION  => $test_data[1]->{dbpath},
});

my $sym = $base->get('smartcards.tokens');
is( ref($sym), 'SCALAR', 'check value of symlink is anon ref to scalar');
is( ${ $sym }, 'connector:connectors.yaml-query-tokens', 'check target of symlink');

$conn = Connector::Multi->new( {
        BASECONNECTOR => $base,
});

my @leaf = sort $conn->get_keys('smartcards');
is($leaf[0], 'owners', 'check that we even get a record with the symlink layout');
is(scalar @leaf, 3, 'should have received three records');

is($conn->get('smartcards.puk'), '007', 'check that we even get a record with a symlink leaf');

is($conn->get('smartcards.tokens.token_1.status'), 'ACTIVATED',
    'multi with symlink config (1)');
is($conn->get('smartcards.owners.joe.tokenid'), 'token_1',
    'multi with symlink simple config (2)');
is($conn->get('smartcards.tokens.token_1.nonexistent'), undef, 'multi with symlink simple config (3)');

# Do Tests using array ref notation
is($conn->get([ ('smartcards','tokens','token_1'),'status' ]), 'ACTIVATED',
    'multi with symlink config and array ref path (1)');
is($conn->get([ 'smartcards','tokens','token_1','status' ]), 'ACTIVATED',
    'multi with symlink config and array ref path (2)');


# Tests on meta data
use Data::Dumper;

# diag "Testing Meta Data";
is( $conn->get_meta('smartcards.puk')->{TYPE} , 'scalar', 'scalar reference');

is( $conn->get_meta('meta.inner' )->{TYPE} , 'hash', 'inner hash node');
is( $conn->get_meta('meta.inner.hash' )->{TYPE} , 'hash', 'outer hash node');
is( $conn->get_meta('meta.inner.hash.key2' )->{TYPE} , 'scalar', 'hash leaf');
is( $conn->get_meta('meta.inner.list' )->{TYPE} , 'list', 'outer list');
is( $conn->get_meta('meta.inner.list.0' )->{TYPE} , 'scalar', 'scalar leaf');
is( $conn->get_meta('meta.inner.single' )->{TYPE} , 'list', 'one item list');
is( $conn->get_meta('meta.inner.single.0' )->{TYPE} , 'scalar', 'scalar leaf');

is( $conn->get_hash('leafref.hash')->{bob}, '007', 'hash with reference in leaf' );
is( $conn->get('cascaded.reference.bob'), 'token_1', 'reference over connector' );
is( $conn->get_hash('cascaded.reference')->{bob}, 'token_1', 'reference over connector with hash' );

is( $conn->get('cascaded.walkover.source.joe.tokenid'), 'token_1', 'reference with walkover' );

my @owners = $conn->get_keys('cascaded.connector.hook.owners');
ok( grep("joe", @owners), 'Hash contains joe' );
is( scalar @owners, 2, 'Hash has two items' );

ok ($conn->exists('smartcards.puk'), 'Exists reference');
ok ($conn->exists('smartcards.owners.joe'), 'connector node exists');
ok ($conn->exists('smartcards.owners.joe.tokenid'), 'connector leaf exists');
ok ($conn->exists( [ 'smartcards', 'owners', 'joe' ] ), 'node exists Array');
ok (!$conn->exists('smartcards.owners.jeff'), 'connector node not exists');

$ENV{OXI_TEST_FOOBAR} = "foobar";
is( $conn->get('envvar.foo.bar'), 'foobar', 'reference from env (regular)' );
#walk over is accepted but prints a warning
is( $conn->get('envvar.foo.bar.baz'), 'foobar', 'reference from env (walk over)' );
# should be undef
is( $conn->get('envvar.foo.baz'), undef, 'reference from env (undef)' );

# should be empty not undef
$ENV{OXI_TEST_FOOBAR} = "";
is( $conn->get('envvar.foo.bar'), '', 'reference from env (empty)' );

is( $conn->get('foo'), undef, 'Cache with prefix - no prefix' );

$conn->PREFIX('cache_test.branch1');
is( $conn->get('foo'), 'test1', 'Cache with prefix - branch 1' );

$conn->PREFIX('cache_test.branch2');
is( $conn->get('foo'), 'test2', 'Cache with prefix - branch 2' );

$conn->PREFIX('');
is( $conn->get('foo'), undef, 'Cache with prefix - no prefix' );

$conn->cleanup();
is(scalar keys %{ $conn->_config() }, 1);
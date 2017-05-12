# Tests for Connector::Proxy::Config::Versioned
#

use strict;
use warnings;
use English;

use Test::More tests => 28;

use Log::Log4perl;
Log::Log4perl->easy_init( { level   => 'ERROR' } );

my $gittestdir = qw( t/config/01-proxy-config-versioned.git );

my $cv_ver2 = '23a1c83c1b43333c146e58fbde269dc7dd87ce8e';
my $cv_ver1 = '6eebdec25d3cbf23d725c4aa48d473943e4a85f3';

# diag "LOAD MODULE\n";

BEGIN {
    my $gittestdir = qw( t/config/01-proxy-config-versioned.git );

    # remove artifacts from previous run
    use Path::Class;
    use DateTime;
    dir($gittestdir)->rmtree;

    # Config::Versioned is used directly to initialize the data source
    {
        use_ok(
            'Config::Versioned',

        );
    };
    use_ok('Connector::Proxy::Config::Versioned');
}

require_ok('Connector::Proxy::Config::Versioned');

# diag "Connector::Proxy::Config::Versioned init\n";
my $cv = Config::Versioned->new(
            {
                dbpath      => $gittestdir,
                autocreate  => 1,
                filename    => '01-proxy-config-versioned-1.conf',
                path        => [qw( t/config )],
                commit_time => DateTime->from_epoch( epoch => 1240341682 ),
                author_name => 'Test User',
                author_mail => 'test@example.com',
            }
);

# Internals: check that the head really points to a commit object
is( $cv->_git()->head->kind, 'commit', 'head should be a commit' );
is( $cv->version, $cv_ver1, 'check version (sha1 hash) of first commit' );

$cv->parser( {
                filename    => '01-proxy-config-versioned-2.conf',
                commit_time => DateTime->from_epoch( epoch => 1240341692 ),
                author_name => 'Test User',
                author_mail => 'test@example.com',
            }
);
ok( $cv, 'create new config instance' );

is( $cv->version, $cv_ver2, 'check version (sha1 hash) of second commit' );

# diag "Connector::Proxy::Config::Versioned tests\n";
###########################################################################
my $conn = Connector::Proxy::Config::Versioned->new(
    {
        LOCATION => $gittestdir,
        PREFIX   => '',
    }
);

ok( $conn, "instance created" ) || die "Unable to continue - no object instance";
is( $conn->get('group1.ldap1.uri'),
    'ldaps://example1.org', 'check single attribute' );
is( $conn->get('nonexistent'), undef, 'check for nonexistent attribute' );

# diag "Test List functionality\n";
my @data = $conn->get_list('list.test');
is( $conn->get_size('list.test'), 4, 'Check size of list');
is( ref \@data, 'ARRAY', 'Check if return is array ref');
is( shift @data, 'first', 'Check element');

# diag "Test Hash functionality\n";
my @keys = $conn->get_keys('group1.ldap');
is( ref \@keys, 'ARRAY', 'Check if get_keys is array ');
is( ref $conn->get_hash('group1.ldap'), 'HASH', 'Check if get_hash is hash');
is( $conn->get_hash('group1.ldap')->{password}, 'secret', 'Check element');

# Test get reference
is( $conn->get_meta('ref.test.link')->{TYPE}, 'reference', 'Check reference');
is( $conn->get_reference('ref.test.link'), 'target', 'Check reference value');

# diag "Test version pointer\n";
is( $conn->get( 'list.test.2'), 'third', 'value from current head');
ok ( $conn->version($cv_ver1), 'Set default version');
is( $conn->version(), $cv_ver1, 'check default version (sha1 hash)' );
is( $conn->get( 'list.test.2'), 'last', 'value from first commit');

is( $conn->get_meta('')->{TYPE}, 'hash', 'Check top node meta');
ok ($conn->exists(''), 'Connector exists');
ok ($conn->exists('list.test'), 'Node Exists');
ok ($conn->exists('list.test.2'), 'Leaf Exists');
ok ($conn->exists( [ 'list','test', 2 ] ), 'Leaf Exists Array');
ok (!$conn->exists('list.baz'), 'Not exists');



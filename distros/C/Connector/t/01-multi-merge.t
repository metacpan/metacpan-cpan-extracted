# Tests for Connector::Proxy::Config::Std
#

use strict;
use warnings;
use English;
use Path::Class;

use Data::Dumper;
use Log::Log4perl qw(:easy);

use Test::More tests => 8;

Log::Log4perl->easy_init($ERROR);

BEGIN {
    use_ok( 'Connector::Multi::Merge' );
    use_ok( 'Connector::Multi' );
}

require_ok( 'Connector::Multi::Merge' );
require_ok( 'Connector::Multi' );

my $base = Connector::Multi::Merge->new({
    LOCATION => 't/config/01-multi-merge.d'
});
 
# Test if base connector is good
is($base->get('base.connectors.conn1.class'), 'Connector::Builtin::Static', 'Base works');

# Load Multi
my $conn = Connector::Multi->new( {
        BASECONNECTOR => $base,
});

# diag "Test Connector::Mutli is working\n";
# Test if multi is good
is($conn->get('base.connectors.conn1.class'), 'Connector::Builtin::Static', 'Multi works');

my @keys = $conn->get_keys('base.parent.node');
is( $keys[0], 'conn1', 'Keys ok');

is($conn->get('base.parent.node.conn1.value'), 'Test', 'Value ok');
    
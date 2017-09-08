use strict;
use warnings;
use English;
use Path::Class;

use Data::Dumper;
use Log::Log4perl qw(:easy);

use Test::More tests => 19;

Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok( 'Connector::Multi::YAML' );
    use_ok( 'Connector::Multi' );
    use_ok( 'Connector::Iterator' );
}

require_ok( 'Connector::Multi::YAML' );
require_ok( 'Connector::Multi' );
require_ok( 'Connector::Iterator' );

my $base = Connector::Multi::YAML->new({
    LOCATION => 't/config/01-tee.yaml'
});

# Test if base connector is good
is($base->get('connectors.conn1.class'), 'Connector::Builtin::Static', 'Base works');

# Load Multi
my $conn = Connector::Multi->new( {
    BASECONNECTOR => $base,
});

# diag "Test Connector::Mutli is working\n";
# Test if multi is good
is($conn->get('connectors.conn1.class'), 'Connector::Builtin::Static', 'Multi works');

is( $conn->get('tee.nodes.static.test'), 'NO');
is( $conn->get('tee.nodes.conn1'), 123);
is( $conn->get('tee.nodes.conn2'), 'ok');

is( $conn->get(['level1','level2','level3','test']), 'ok');

# change acceptance rule
$conn->get_connector('tee')->accept('');
is( $conn->get(['level1','level2','level3','test']), 'NO');

# change acceptance rule
$conn->get_connector('tee')->accept('\A\d+\z');
is( $conn->get(['level1','level2','level3','test']), '123');

# list test - remove the scalar sources
$conn->get_connector('tee')->accept('');
$conn->get_connector('tee')->branches(['static','conn3']);

# this node does not exists in the static branch
my @res = $conn->get_list(['level1','level2','level3','list','test']);
ok(@res);
is(@res, 4);

# hash test
my $res = $conn->get_hash(['level1','level2','level3','test','entry']);
ok($res);
is(ref $res, 'HASH');
is($conn->get(['level1','level2','level3','test','entry','foo']), '1234');




# Tests for Connector::Proxy::Config::Std
#

use strict;
use warnings;
use English;
use Path::Class;

use Data::Dumper;
use Log::Log4perl qw(:easy);

use Test::More tests => 18;

Log::Log4perl->easy_init($ERROR);

BEGIN {
    use_ok( 'Connector::Multi::YAML' );
    use_ok( 'Connector::Multi' );
    use_ok( 'Connector::Iterator' );
}

require_ok( 'Connector::Multi::YAML' );
require_ok( 'Connector::Multi' );
require_ok( 'Connector::Iterator' );

my $base = Connector::Multi::YAML->new({
    LOCATION => 't/config/01-iterator.yaml'
});
 
# Test if base connector is good
is($base->get('connectors.conn1.class'), 'Connector::Builtin::File::Path', 'Base works');

# Load Multi
my $conn = Connector::Multi->new( {
        BASECONNECTOR => $base,
});

# diag "Test Connector::Mutli is working\n";
# Test if multi is good
is($conn->get('connectors.conn1.class'), 'Connector::Builtin::File::Path', 'Multi works');

# Create Iterator - autodiscovery mode with error handling
my $target = Connector::Iterator->new({
    BASECONNECTOR => $conn,
    PREFIX => ['level1','level2','level3'],
    skip_on_error => 1,
}); 

ok($target);

my $res = $target->set('test', { data => 'testdata' });
ok(-e 't/config/test.txt', 'conn1 file is there');
is(`cat t/config/test.txt`, 'testdata');
is( $res->{conn1}, '' );
like( $res->{conn2}, "/open file for writing/" );
unlink('t/config/test.txt');

# let write error bubble up - with autodiscover
$target = Connector::Iterator->new({
    BASECONNECTOR => $conn,
    PREFIX => ['level1','level2','level3'],
    skip_on_error => 0,
}); 
eval {
    $target->set('test', { data => 'testdata' });
};
like( $EVAL_ERROR, "/open file for writing/" );

# explicit target
$target = Connector::Iterator->new({
    BASECONNECTOR => $conn,
    PREFIX => ['level1','level2','level3'],
    skip_on_error => 0,
    target => [ 'conn1' ]
}); 

$res = {};
eval {
    $res = $target->set('test', { data => 'testdata' });
};

ok(-e 't/config/test.txt', 'conn1 file is there');
is( $res->{conn1}, '' );
ok( !defined $res->{conn2} );
is( $EVAL_ERROR, '' ); 


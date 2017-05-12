# Tests for Connector::Proxy::Net::LDAP
#

use strict;
use warnings;
use English;
use Data::Dumper;

use Test::More tests => 19;

diag "LOAD MODULE\n";

BEGIN {
    use_ok( 'Config::Versioned' );
    use_ok( 'Connector::Multi' );
    use_ok( 'Connector::Proxy::Config::Versioned' );
    use_ok( 'Connector::Proxy::Net::LDAP' ); 
}

require_ok( 'Config::Versioned' );
require_ok( 'Connector::Multi' );
require_ok( 'Connector::Proxy::Config::Versioned' );
require_ok( 'Connector::Proxy::Net::LDAP' );

diag "Connector::Proxy::Net::LDAP tests\n";
###########################################################################

my $cv = Config::Versioned->new(
    {
            dbpath => 't/config/01-proxy-net-ldap-config.git',
            autocreate => 1,
            filename => '01-proxy-net-ldap.conf',
            path => [ qw( t/config ) ],
            author_name => 'Test User',
            author_mail => 'test@example.com',
    }
) or die "Error creating Config::Versioned: $@";

my $base = Connector::Proxy::Config::Versioned->new( {    
    LOCATION => 't/config/01-proxy-net-ldap-config.git',
});
my $conn = Connector::Multi->new( {
    BASECONNECTOR => $base,    
});

SKIP: {
# Check if connector is set up
if (!$conn->get('connectors.do_tests')) {
    skip 'Please setup ldap config in 01-proxy-net-ldap.conf', 11;
}
    
# Test if the connector is a symlink 
is ( ref $conn->get('test.basic'), 'SCALAR', 'connector link is scalar ref' );
is ( ${$conn->get('test.basic')}, 'connector:connectors.ldap', 'Name of Connector ' );

my $sSubject = sprintf "%01x.example.org", rand(10000000);

diag "Random Subject: $sSubject\n"; 

is ( $conn->get(['test.basic', $sSubject]), undef, 'Node not found in LDAP');
is ( $conn->set(['test.basic', $sSubject], 'IT Department'), 1, 'Create Node and Attribute');
is ( $conn->get(['test.basic', $sSubject]), 'IT Department', 'Attribute found');
is ( $conn->get(['test.single', $sSubject]) , 'IT Department', 'Find Attribute using Single');

# Set uid using Single 
is ( $conn->set(['test.single', $sSubject], ['login1', 'login2'] ), 1, 'Create Node and Attribute');

# Load connector to manipulate config
my $ldap = $conn->get_connector('connectors.ldap-single');

# Update Attribute Map
$ldap->attrmap( { usermail => 'mail', department => 'ou', ntlogin => 'uid' } );

my $hash = $conn->get_hash(['test.single', $sSubject], { deep => 1 });

is ( $hash->{usermail}, 'it-department@openxopki.org', 'usermail attribute ok using Single');
is ( $hash->{department}, 'IT Department', 'department attribute ok using Single');
is ( ref $hash->{ntlogin}, 'ARRAY', 'ntlogin is array ref');
is ( $hash->{ntlogin}->[1], 'login2', 'login2 ok');

is ( $conn->set(['test.basic', $sSubject], undef), 1, 'Clear Attribute');
is ( $conn->get(['test.basic', $sSubject]), undef, 'Attribute absent');

my @keys = $conn->get_keys(['test.single', $sSubject]);
is ( @keys, 3, 'Keymap size ok');

}
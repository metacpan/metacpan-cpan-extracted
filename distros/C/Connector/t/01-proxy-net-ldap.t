# Tests for Connector::Proxy::Net::LDAP
#

use strict;
use warnings;
use English;
use Data::Dumper;

use Log::Log4perl qw( :easy );
BEGIN {
    use Test::More;

    unless ( $ENV{CONN_HAVE_LDAP_SERVER} ) {
        plan skip_all => "Skipping LDAP tests because there might be no server";
        exit;
    }

    use_ok( 'Net::LDAP' );
    use_ok( 'Config::Versioned' );
    use_ok( 'Connector::Multi' );
    use_ok( 'Connector::Proxy::Config::Versioned' );
    use_ok( 'Connector::Proxy::Net::LDAP' );
}

require_ok( 'Net::LDAP' );
require_ok( 'Config::Versioned' );
require_ok( 'Connector::Multi' );
require_ok( 'Connector::Proxy::Config::Versioned' );
require_ok( 'Connector::Proxy::Net::LDAP' );

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


Log::Log4perl->easy_init($ERROR);


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

my $sSubject = sprintf "%01x.example.org", rand(10000000);
# diag "Random Subject: $sSubject\n";

# diag "Test with Simple connector";
is ( $conn->get(['test','basic', $sSubject]), undef, 'Node not found in LDAP');
is ( $conn->set(['test','basic', $sSubject], 'IT Department'), 1, 'Create Node and Attribute');
is ( $conn->get(['test','basic', $sSubject]), 'IT Department', 'Attribute found');

# Simulate a timeout / disconnect
$conn->get_connector('connectors.ldap')->ldap()->disconnect();
is ( $conn->get(['test','basic', $sSubject]), 'IT Department', 'Attribute found after reconnect');


# diag "Test with Single connector";
# Set uid using Single
is ( $conn->set(['test','single', $sSubject], { 'ntlogin' => ['login1', 'login2'] } ), 1, 'Create Node and Attribute');

# Load connector to manipulate config
my $ldap = $conn->get_connector('connectors.ldap-single');

# Update Attribute Map
$ldap->attrmap( { usermail => 'mail', department => 'ou', ntlogin => 'uid' } );

my $hash = $conn->get_hash(['test','single', $sSubject], { deep => 1 });

is ( $hash->{usermail}, 'it-department@openxopki.org', 'usermail attribute ok using Single');
is ( $hash->{department}, 'IT Department', 'department attribute ok using Single');
is ( ref $hash->{ntlogin}, 'ARRAY', 'ntlogin is array ref');
is ( $hash->{ntlogin}->[1], 'login2', 'login2 ok');

is( $conn->set( 'test.single.xxxx' , { 'ntlogin' => undef }, { pkey => $hash->{pkey} } ), 1, 'Delete by DN');

my @keys = $conn->get_keys(['test','single', $sSubject]);

is ( @keys, 3, 'Keymap size ok');

# diag "Test action settings";

is( $conn->set(['test','single',$sSubject], { 'usermail' => [ 'test@test.local', 'test2@test.local' ] }), 1, 'Set usermail');

$ldap->action('append');
is( $conn->set(['test','single',$sSubject], { 'usermail' => [ 'test3@test.local' ] } ), 1, 'Append');

$hash = $conn->get_hash(['test','single', $sSubject], { deep => 1 });
is ( $hash->{usermail}->[1], 'test2@test.local');

$ldap->action('delete');
is( $conn->set(['test','single',$sSubject], { 'usermail' => [ 'test2@test.local' ] } ), 1, 'Delete item');
$hash = $conn->get_hash(['test','single', $sSubject], { deep => 1 });
is ( $hash->{usermail}->[1], 'test3@test.local');


my @dn = $conn->get_list( ['test','dn', $sSubject] );
is ( $conn->set( ['test','dn', $sSubject] , undef, { pkey => shift @dn }), 1, 'Deleting node');
is ( $conn->get(['test','basic', $sSubject]), undef, 'Node was deleted');

}

done_testing;


use Test::More;

use Authen::Pluggable;
use Mojo::Log;
use Mojo::File 'path';

my %opt;

foreach (qw/user pass server managerDN managerPassword searchBase/) {
    $opt{$_} = $ENV{ 'LDAP_' . uc($_) }
        // plan skip_all => 'set LDAP_' . uc($_) . ' to enable this test';
}

my $user = delete $opt{'user'};
my $pass = delete $opt{'pass'};

my $log  = $ENV{DEBUG} ? Mojo::Log->new( color => 1 ) : undef;
my $auth = new Authen::Pluggable( log => $log );

isa_ok(
    $auth->providers(
        {   'Passwd' =>
                { 'file' => path(__FILE__)->sibling('users1')->to_string },
            'AD' => \%opt,
        }
    ),
    'Authen::Pluggable'
);

my $uinfo = $auth->authen( 'foo', 'foo' );

is( $uinfo->{user},     'foo',      'Passwd: User authenticated' );
is( $uinfo->{provider}, 'Passwd',    'Passwd: Correct provider response' );
is( $uinfo->{cn},       'Test User', 'Passwd: Common name available' );

$uinfo = $auth->authen( $user, $pass );

is( $uinfo->{user},     $user, 'AD: User authenticated' );
is( $uinfo->{provider}, 'AD',  'AD: Correct provider response' );
$ENV{LDAP_CN}
    ? is( $uinfo->{cn}, $ENV{LDAP_CN}, 'AD: Common name available' )
    : diag("Set LDAP_CN to check common name");
$ENV{LDAP_MAIL}
    ? is( $uinfo->{mail}, $ENV{LDAP_MAIL}, 'AD: Mail available' )
    : diag("Set LDAP_MAIL to check user mail");

done_testing();

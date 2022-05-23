use Test::More;

use Authen::Pluggable;
use Mojo::Log;
use Mojo::File 'path';

my $provider = 'Passwd';

my $user = 'foo';
my $pass = 'foo';

my $log  = $ENV{DEBUG} ? Mojo::Log->new( color => 1 ) : undef;
my $auth = new Authen::Pluggable( log => $log );

isa_ok(
    $auth->provider($provider)->cfg(
        'file' => path(__FILE__)->sibling('users1')->to_string
    ),
    'Authen::Pluggable'
);

my $uinfo = $auth->authen( $user, '' );
is( $uinfo->{user},     undef,       'User no authenticated (missing pass)' );

my $uinfo = $auth->authen( $user, $pass.$pass );
is( $uinfo->{user},     undef,       'User no authenticated (wrong pass)' );

my $uinfo = $auth->authen( $user, $pass );

is( $uinfo->{user},     $user,       'User authenticated' );
is( $uinfo->{provider}, $provider,   'Correct provider response' );
is( $uinfo->{cn},       'Test User', 'Common name available' );

done_testing();

use Test::More;

use strict;
use warnings;

use CGI::Application::Plugin::Throttle;

$ENV{ REMOTE_ADDR } = '192.169.0.1';
$ENV{ REMOTE_USER } = 'Test User';
$ENV{ HTTP_USER_AGENT } = 'TAP';

my $mock_cgi = bless {}, 'MyCGI';
my $throttle = throttle($mock_cgi);
$throttle->configure( prefix => 'Mocked CGI' ) ;

my $keys = $throttle->_get_keys;

is( $keys => undef,
    "Only 'undef', we should not throttle"
);

done_testing();

package MyCGI;

sub throttle_keys {
    return undef
}
1;

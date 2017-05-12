use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 4, todo => [] }

# load your module...
use Authen::SASL;

my $sasl= Authen::SASL->new('DIGEST-MD5') or die;
$sasl->callback('auth' => 'harness',
                'password' => 'secret',
                'user' => 'somebody',
               );
my $con = $sasl->client_new('imap', 'localhost')
  or die $sasl->error;

my $server_output='nonce="3QcmMSzgYToomMPhU7qOrM58XdeVZ9pAIZ+d9AWie1A=",realm="perltest",qop="auth,auth-int,auth-conf",cipher="rc4-40,rc
56,rc4",maxbuf=4096,charset=utf-8,algorithm=md5-sess';

my $step = $con->client_step($server_output) or die $con->error;

$step =~ /authzid="(.*?)"/;
ok($1 eq 'somebody');
$step =~ /username="(.*?)"/;
ok($1 eq 'harness');

$sasl= Authen::SASL->new('mechanism' => 'DIGEST-MD5',
                         'callback'  => {
                                         'password' => 'secret',
                                         'user'     => 'somebody',
                                         'auth'     => 'harness',
                                        }
                           ) or die;
$con = $sasl->client_new('imap', 'localhost')
  or die $sasl->error;
$step = $con->client_step($server_output) or die $con->error;

$step =~ /authzid="(.*?)"/;
ok($1 eq 'somebody');
$step =~ /username="(.*?)"/;
ok($1 eq 'harness');

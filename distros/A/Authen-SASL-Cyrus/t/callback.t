use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
#BEGIN { plan tests => 11, todo => [] }
BEGIN { plan tests => 8, todo => [] }

# load your module...
use Authen::SASL;

ok(1);
my $sasl= Authen::SASL->new(
                            'password' => sub { ok(1); return 'secret' },
                            'mechanism' => 'DIGEST-MD5',
                            'user' => sub { ok(1); return 'somebody' },
                           ) or die;
ok(&{$sasl->{callback}->{pass}} eq 'secret');
ok(&{$sasl->{callback}->{user}} eq 'somebody');
ok(&{$sasl->{user}} eq 'somebody');
ok($sasl->{mechanism} eq 'DIGEST-MD5');
#my $con = $sasl->client_new('imap', 'localhost')
#  or die $sasl->error;
#my $so = 'nonce="3QcmMSzgYToomMPhU7qOrM58XdeVZ9pAIZ+d9AWie1A=",realm="localhost",qop="auth,auth-int,auth-conf",cipher="rc4-40,rc4-56,rc4
#maxbuf=4096,charset=utf-8,algorithm=md5-sess';
#my $step = $con->client_step($so);
#ok($step);

use strict;
use Test;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 6, todo => [] }

# load your module...
use Authen::SASL;

ok(1);
my $sasl= Authen::SASL->new(
                            'password' => 'secret',
                            'mechanism' => 'DIGEST-MD5',
                            'user' => 'somebody',
                           ) or die;
ok($sasl->{callback}->{pass} eq 'secret');
ok($sasl->{callback}->{user} eq 'somebody');
ok($sasl->{user} eq 'somebody');
ok($sasl->{mechanism} eq 'DIGEST-MD5');
my $con = $sasl->client_new('imap', 'localhost')
  or die $sasl->error;
ok(1);

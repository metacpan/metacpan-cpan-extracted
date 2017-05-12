use strict;
use warnings;
use Test::More tests => 2;
use Crypt::Skip32::XS;

my $key   = pack('H20', '112233445566778899AA');
my $crypt = Crypt::Skip32::XS->new($key);
isa_ok($crypt, 'Crypt::Skip32::XS', 'new($key)');
can_ok('Crypt::Skip32::XS', qw(blocksize keysize decrypt encrypt));

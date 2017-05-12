use strict; use warnings;
use Test::More tests => 2;
use Crypt::Hill;

my $crypt = Crypt::Hill->new({ key => 'DDCF' });

is($crypt->encode('HELP'), 'HIAT');
is($crypt->decode('HIAT'), 'HELP');

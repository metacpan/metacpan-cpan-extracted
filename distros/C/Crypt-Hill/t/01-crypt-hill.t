use strict; use warnings;
use Test::More tests => 4;
use Crypt::Hill;

eval { Crypt::Hill->new({ key => 'BCBC' }); };
like($@, qr/ERROR: Invalid key/);

eval { Crypt::Hill->new({ key => 'BCBCB' }); };
like($@, qr/ERROR: Key should be of length 4/);

eval { Crypt::Hill->new({ key => 'BCB' }); };
like($@, qr/ERROR: Key should be of length 4/);

eval { Crypt::Hill->new; };
like($@, qr/Missing required arguments: key/);

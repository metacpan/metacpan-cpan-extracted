use strict;
use warnings;

use Test::More import => ['!pass'];

{
	use Dancer2;

	BEGIN {
		set plugins => { JWT => { secret => undef }};
	}

    eval "use Dancer2::Plugin::JWT";
    like $@, qr/JWT cannot be used without a secret/;

}

done_testing();

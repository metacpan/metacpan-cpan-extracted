use strict;
use warnings;

use Test::More import => ['!pass'];

plan tests => 2;

##
## Test detection of missing configuration settings
##
{
	use Dancer;
	use Dancer::Plugin::EncodeID;

	## This should "die" because configuration settings
	## for Plugins::EncodeID::secret is NOT defined
	eval {
		my $hashed_id = encode_id ( 50 ) ;
	};
	if ($@) {
		## 'encode_id()' died, so it's OK
		Test::More::pass("detect missing config-settings");
	} else {
		fail("detect missing config-settings");
	}
}

##
## Encode something, when configuration settings do exist
##
{
	use Dancer;
	use Dancer::Plugin::EncodeID;

	my $secret = "hello_world";
	setting plugins => { EncodeID => { secret => $secret } };

	eval {
		my $hashed_id = encode_id ( 50 ) ;
	};
	if ($@) {
		## 'encode_id()' died, configuration settings was not detected
		fail("detect valid config-settings");
	} else {
		Test::More::pass("detect valid config-settings");
	}
}

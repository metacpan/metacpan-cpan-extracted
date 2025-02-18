use strict;

use Test::More;
use Test::Exception;

use_ok 'AnyEvent::Filesys::Watcher';

lives_ok {
	AnyEvent::Filesys::Watcher->new(
		directories => ['t'],
		cb => sub {}
	);
} 'parameter cb should work as an alias for callback';

done_testing;

use Test::Most 'die', tests => 14;

use_ok('ful');

use_ok('ful', qw/one two/);

use_ok('ful', { libdirs => [qw/one two/] });

use_ok('ful', { file => '.project-base' });

use_ok('ful', { target => '.project-base' });

use_ok('ful', { target_file => '.project-base' });

use_ok('ful', { git => 1 });

use_ok('ful', { dir => '.nonexistent' });

use_ok('ful', { has_dir => 't' });

use_ok('ful', { child_dir => 't2' });

require_ok('ful');

like(ful::crum(), qr/\/t$/, 'ful::crum()');
like($ful::crum, qr/\/t$/, '$ful::crum');

is($ful::crum, ful::crum(), 'ful::crum() == $ful::crum');

done_testing;
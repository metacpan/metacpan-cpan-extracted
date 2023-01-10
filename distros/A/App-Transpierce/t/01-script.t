use v5.10;
use strict;
use warnings;

use Test::More;
use Test::Script;
use File::Path qw(rmtree);
use File::Copy qw(copy);

use lib 't/lib';
use FileTests;

# Keep this commented out to avoid wide character print warnings. The testing
# code seems to work properly anyway
# use utf8;

use constant SCRIPT_PATH => 'bin/transpierce';
use constant TESTDIR => 't/testdir';

sub test_working_env
{
	my ($dir) = @_;

	my %compare = (
		$dir . '/restore/UP__data__f3.txt' => 't/data/f3.txt',
		$dir . '/deploy/UP__data__f3.txt' => 't/data/f3.txt',
		$dir . '/restore/UP__data__d1__d11/f1.txt' => 't/data/d1/d11/f1.txt',
		$dir . '/deploy/UP__data__d1__d11/f1.txt' => 't/data/d1/d11/f1.txt',
		$dir . '/restore/UP__data__d2__d21/f2.txt' => 't/data/d2/d21/f2.txt',
		$dir . '/deploy/UP__data__d2__d21/f2.txt' => 't/data/d2/d21/f2.txt',

		# this is a new file, so it should be empty
		$dir . '/deploy/UP__data__d2__d21/newdir__fnew.txt' => qr/\A\z/,
	);

	for my $key (keys %compare) {
		my $value = $compare{$key};

		files_content_same($key, $value);
	}

	files_content_same(
		$dir . '/deploy.sh',
		qr{
			\A \s*
			cp [ ] "deploy/UP__data__f3\.txt" [ ] "\.\./data/f3\.txt" \v
			chmod [ ] 0[0-7]{3} [ ] "\.\./data/f3\.txt" \v
			chown [ ] \d+ [ ] "\.\./data/f3\.txt" \v
			chgrp [ ] \d+ [ ] "\.\./data/f3\.txt" \v
			\v
			cp [ ] "deploy/UP__data__d1__d11/f1\.txt" [ ] "\.\./data/d1/d11/f1\.txt" \v
			chmod [ ] 0[0-7]{3} [ ] "\.\./data/d1/d11/f1\.txt" \v
			chown [ ] \d+ [ ] "\.\./data/d1/d11/f1\.txt" \v
			chgrp [ ] \d+ [ ] "\.\./data/d1/d11/f1\.txt" \v
			\v
			cp [ ] "deploy/UP__data__d2__d21/f2\.txt" [ ] "\.\./data/d2/d21/f2\.txt" \v
			chmod [ ] 0[0-7]{3} [ ] "\.\./data/d2/d21/f2\.txt" \v
			chown [ ] \d+ [ ] "\.\./data/d2/d21/f2\.txt" \v
			chgrp [ ] \d+ [ ] "\.\./data/d2/d21/f2\.txt" \v
			\v
			mkdir [ ] -p [ ] "\.\./data/d2/d21/newdir/" \v
			cp [ ] "deploy/UP__data__d2__d21/newdir__fnew\.txt" [ ] "\.\./data/d2/d21/newdir/fnew\.txt" \v
			chmod [ ] 0666 [ ] "\.\./data/d2/d21/newdir/fnew\.txt" \v
			chown [ ] user [ ] "\.\./data/d2/d21/newdir/fnew\.txt" \v
			chgrp [ ] group [ ] "\.\./data/d2/d21/newdir/fnew\.txt" \v
			\s* \z
		}x
	);

	files_content_same(
		$dir . '/restore.sh',
		qr{
			\A \s*
			cp [ ] "restore/UP__data__f3\.txt" [ ] "\.\./data/f3\.txt" \v
			chmod [ ] 0[0-7]{3} [ ] "\.\./data/f3\.txt" \v
			chown [ ] \d+ [ ] "\.\./data/f3\.txt" \v
			chgrp [ ] \d+ [ ] "\.\./data/f3\.txt" \v
			\v
			cp [ ] "restore/UP__data__d1__d11/f1\.txt" [ ] "\.\./data/d1/d11/f1\.txt" \v
			chmod [ ] 0[0-7]{3} [ ] "\.\./data/d1/d11/f1\.txt" \v
			chown [ ] \d+ [ ] "\.\./data/d1/d11/f1\.txt" \v
			chgrp [ ] \d+ [ ] "\.\./data/d1/d11/f1\.txt" \v
			\v
			cp [ ] "restore/UP__data__d2__d21/f2\.txt" [ ] "\.\./data/d2/d21/f2\.txt" \v
			chmod [ ] 0[0-7]{3} [ ] "\.\./data/d2/d21/f2\.txt" \v
			chown [ ] \d+ [ ] "\.\./data/d2/d21/f2\.txt" \v
			chgrp [ ] \d+ [ ] "\.\./data/d2/d21/f2\.txt" \v
			\v
			rm [ ] "\.\./data/d2/d21/newdir/fnew\.txt"
			\s* \z
		}x
	);

	files_content_same(
		$dir . '/diff.sh',
		qr{
			\A \s*
			echo [ ] "\.\./data/f3\.txt" \v
			diff [ ] "restore/UP__data__f3\.txt" [ ] "\.\./data/f3\.txt" \v
			\v
			echo [ ] "\.\./data/d1/d11/f1\.txt" \v
			diff [ ] "restore/UP__data__d1__d11/f1\.txt" [ ] "\.\./data/d1/d11/f1\.txt" \v
			\v
			echo [ ] "\.\./data/d2/d21/f2\.txt" \v
			diff [ ] "restore/UP__data__d2__d21/f2\.txt" [ ] "\.\./data/d2/d21/f2\.txt" \v
			\v
			ls [ ] -l [ ] "\.\./data/d2/d21/newdir/fnew\.txt" \v
			\s* \z
		}x
	);
}

subtest 'should work when conf is inside target' => sub {
	my $output;

	rmtree TESTDIR;
	mkdir TESTDIR;
	copy('t/transpierce.conf', TESTDIR . '/transpierce.conf');

	script_runs(
		[SCRIPT_PATH, TESTDIR], {
			stdout => \$output,
		},
		'script runs ok'
	);

	# no output in normal generation
	ok !$output, 'output ok';

	test_working_env(TESTDIR);
};

subtest 'should work with -c outside target and directory not existing' => sub {
	my $output;

	rmtree TESTDIR;

	script_runs(
		[SCRIPT_PATH, '-c', 't/transpierce.conf', TESTDIR], {
			stdout => \$output,
		},
		'script runs ok'
	);

	# no output in normal generation
	ok !$output, 'output ok';

	test_working_env(TESTDIR);
};

rmtree TESTDIR;

done_testing;


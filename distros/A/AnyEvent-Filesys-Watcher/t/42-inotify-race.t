# GitHub issue https://github.com/mvgrimes/AnyEvent-Filesys-Notify/issues/11.
# Previous implementation had a race condition which could miss entities
# created inside a newly create directory.

use strict;
use warnings;

use File::Spec;
use Test::More;

use AnyEvent::Filesys::Watcher;
use lib 't/lib';
use TestSupport qw(create_test_files delete_test_files move_test_files
	modify_attrs_on_test_files test EXISTS DELETED);

if ($^O eq 'MSWin32' ) {
	plan skip_all => 'Test temporarily disabled for MSWin32';
}

$|++;

test(
	setup => sub { create_test_files qw(one/1 two/1) },
	description => 'create two directories with one file each',
	expected => {
		one => EXISTS,
		'one/1' => EXISTS,
		two => EXISTS,
		'two/1' => EXISTS,
	},
	ignore => '.',
);

# ls: one/1 two/1
test(
	setup => sub { create_test_files qw(one/sub/2) },
	description => 'create subdir and file',
	expected => {
		'one/sub' => EXISTS,
		'one/sub/2' => EXISTS,
	},
	ignore => '.',
);

done_testing;

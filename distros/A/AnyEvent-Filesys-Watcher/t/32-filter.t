use strict;
use warnings;

use Test::More;
use File::Spec;

use lib 't/lib';
use TestSupport qw(create_test_files delete_test_files move_test_files
	modify_attrs_on_test_files test EXISTS DELETED);

$|++;

# Filters can only be tested with the fallback backend.  The other backends
# may merge events and that make it hard to synchronize.

test(
	setup => sub { create_test_files(qw(foo ignoreme)) },
	description => 'scalar filter',
	expected => {
		foo => EXISTS,
	},
	filter => '/foo$',
	backend => 'Fallback',
);

test(
	setup => sub { create_test_files(qw(foo ignoreme)) },
	description => 'regexp filter',
	expected => {
		foo => EXISTS,
	},
	filter => qr{/foo$},
	backend => 'Fallback',
);

test(
	setup => sub { create_test_files(qw(foo ignoreme)) },
	description => 'code reference filter',
	expected => {
		foo => EXISTS,
	},
	filter => sub { shift->path =~ m{/foo$} },
	backend => 'Fallback',
);

done_testing;

use strict;
use warnings;
use Test::More;

use Data::Hash::Patch::Smart qw(patch);

# ------------------------------------------------------------
subtest 'wildcard + cycles' => sub {
	my $x = {};
	$x->{self} = $x;

	my $changes = [
		{ op => 'change', path => '/self/*/value', to => 'X' },
	];

	eval { patch($x, $changes, strict => 1) };

	like $@, qr/Cycle detected/, 'cycle detected during structural wildcard patch';
};

# ------------------------------------------------------------
subtest 'wildcard + create_missing' => sub {
	my $data = {};

	my $changes = [
		{ op => 'change', path => '/a/*/c', to => 123 },
	];

	my $patched = patch($data, $changes, create_missing => 1);

	is_deeply $patched, {}, 'wildcard + create_missing does nothing when no matches exist';
};

# ------------------------------------------------------------
subtest 'wildcard + strict (missing path)' => sub {
	my $data = { a => {} };

	my $changes = [
		{ op => 'change', path => '/a/*/x', to => 1 },
	];

	eval { patch($data, $changes, strict => 1) };
	is $@, '', 'wildcard + strict does not error on missing matches';
};

# ------------------------------------------------------------
subtest 'wildcard + unordered arrays (leaf only)' => sub {
	my $data = { items => [ 'a', 'b', 'c' ] };

	my $changes = [
		{ op => 'remove', path => '/items/*', from => 'b' },
	];

	my $patched = patch($data, $changes);

	is_deeply $patched, { items => [ 'a', 'c' ] },
		'unordered wildcard remove works';
};

# ------------------------------------------------------------
subtest 'wildcard + deep nesting' => sub {
	my $data = {
		root => {
			level1 => {
				a => { x => 1 },
				b => { x => 2 },
				c => { x => 3 },
			}
		}
	};

	my $changes = [
		{ op => 'change', path => '/root/level1/*/x', to => 99 },
	];

	my $patched = patch($data, $changes);

	is_deeply $patched, {
		root => {
			level1 => {
				a => { x => 99 },
				b => { x => 99 },
				c => { x => 99 },
			}
		}
	}, 'deep wildcard patching works';
};

# ------------------------------------------------------------
subtest 'wildcard + mixed arrays and hashes' => sub {
	my $data = {
		items => [
			{ name => 'a', val => 1 },
			{ name => 'b', val => 2 },
			{ name => 'c', val => 3 },
		]
	};

	my $changes = [
		{ op => 'change', path => '/items/*/val', to => 10 },
	];

	my $patched = patch($data, $changes);

	is_deeply $patched, {
		items => [
			{ name => 'a', val => 10 },
			{ name => 'b', val => 10 },
			{ name => 'c', val => 10 },
		]
	}, 'wildcard works on arrays of hashes';
};

# ------------------------------------------------------------
subtest 'wildcard + multiple matches' => sub {
	my $data = {
		users => {
			alice => { role => 'user' },
			bob   => { role => 'user' },
			carol => { role => 'user' },
		}
	};

	my $changes = [
		{ op => 'change', path => '/users/*/role', to => 'admin' },
	];

	my $patched = patch($data, $changes);

	is_deeply $patched, {
		users => {
			alice => { role => 'admin' },
			bob   => { role => 'admin' },
			carol => { role => 'admin' },
		}
	}, 'wildcard applies to all matching children';
};

# ------------------------------------------------------------
subtest 'wildcard + no matches' => sub {
	my $data = { a => {} };

	my $changes = [
		{ op => 'change', path => '/a/*/x', to => 1 },
	];

	my $patched = patch($data, $changes);

	is_deeply $patched, { a => {} },
		'wildcard silently does nothing when no matches exist';
};

# ------------------------------------------------------------
subtest 'wildcard + remove' => sub {
	my $data = {
		users => {
			alice => { active => 1 },
			bob   => { active => 1 },
		}
	};

	my $changes = [
		{ op => 'remove', path => '/users/*/active' },
	];

	my $patched = patch($data, $changes);

	is_deeply $patched, {
		users => {
			alice => {},
			bob   => {},
		}
	}, 'wildcard remove works';
};

# ------------------------------------------------------------
subtest 'wildcard + add' => sub {
	my $data = {
		users => {
			alice => {},
			bob   => {},
		}
	};

	my $changes = [
		{ op => 'add', path => '/users/*/role', value => 'guest' },
	];

	my $patched = patch($data, $changes);

	is_deeply $patched, {
		users => {
			alice => { role => 'guest' },
			bob   => { role => 'guest' },
		}
	}, 'wildcard add works';
};

done_testing;

#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 236);
}

# tests for _path, normalize_key, key and path...

my $h = Data::SimplePath -> new ();

# we test these separator strings:
foreach my $s ('/', '#', '::', '\.~*$') {

	$h -> separator ($s);

	# empty key or a key consisting only of separators must be an empty path:
	foreach my $c (0 .. 3) {
		my @p = $h -> path ($s x $c);
		is_deeply (\@p, [], 'Empty path');
	}

	foreach my $a (['a'], ['a', 'b'], ['a', '.*{1}', '-', 'd']) {

		# simple key string:
		my $key = join $s, @$a;
		my @p = $h -> path ($key);
		is_deeply (\@p, $a, "Correct path for $key");
		is ($h -> key ( @p), $key, 'Key ok');
		is ($h -> key (\@p), $key, 'Key ok');
		@p = $h -> _path ($key);
		is_deeply (\@p, $a, '_path ok');

		# separators at beginning/end must be ignored:
		@p = $h -> path ($s . $key . $s);
		is_deeply (\@p, $a, "Correct path for $s$key$s");
		is ($h -> key ( @p), $key, 'Key ok');
		is ($h -> key (\@p), $key, 'Key ok');
		@p = $h -> _path ($s . $key . $s);
		is_deeply (\@p, $a, '_path ok');

		# multiple consecutive separators must be handled as one separator:
		$key = join "$s$s", @$a;
		@p = $h -> path ($s . $s . $s . $key . $s . $s . $s);
		is_deeply (\@p, $a, "Correct path for $s$s$s$key$s$s$s");
		is ($h -> key ( @p), $h -> normalize_key ($key), 'Normalized key ok');
		is ($h -> key (\@p), $h -> normalize_key ($key), 'Normalized key ok');
		@p = $h -> _path ($s . $key . $s);
		is_deeply (\@p, $a, '_path ok');

		# _path directly with the arrayref:
		@p = $h -> _path ($a);
		is_deeply (\@p, $a, '_path ok');

	}

	# more tests for the key () method:
	foreach my $p (
		[],
		['a'],
		['a', 'b', 'c'],
		['a', '', 'b', '', 'c'],
		['', 'a', 1, 2, {}, '']	        # the docs don't restrict what elements to use...
	) {

		my $k1 = $h -> key (@$p);       # must work with lists ...
		my $k2 = $h -> key ( $p);       # ... and arrayrefs

		# according to the docs the result must be the same as with join:
		is ($k1, join ($h -> separator (), @$p), 'Join for @ correct');
		is ($k2, join ($h -> separator (), @$p), 'Join for $ correct');

	}

}

# some special tests for the normalize_key method:
my %keys = (
	# separator     # key to test           # expected result
	'/'     => {
			''                      => '',                  # the most basic case
			'/'                     => '',
			'/a/'                   => 'a',
			'/a/b/c/'               => 'a/b/c',
			'///'                   => '',
			'//a///b//c//'          => 'a/b/c',
			'a/b/c'                 => 'a/b/c'
	},
	'::'    => {
			''                      => '',                  # maybe we should mention that
			':'                     => ':',                 # using a separator string like
			'::a:'                  => 'a:',                # this could be a bit confusing
			'::a::b::c::'           => 'a::b::c',
			'::::::'                => '',
			'::::a::b::::c:'        => 'a::b::c:',
			'a::b::c'               => 'a::b::c',
			'a:::b::c'              => 'a:::b::c',
	},
	'*~$'   => {
			''                      => '',                  # ugly, but not confusing :)
			'*~$'                   => '',
			'*~$a*~$'               => 'a',
			'*~$a*~$b*~$c*~$'       => 'a*~$b*~$c',
			'*~$*~$*~$'             => '',
			'*~$*~$a*~$*~$b*~$c'    => 'a*~$b*~$c',
			'a*~$b*~$c'             => 'a*~$b*~$c',
	},
);

while (my ($s, $vals) = each %keys) {
	$h -> separator ($s);
	while (my ($key, $nkey) = each %$vals) {
		is ($h -> normalize_key ($key), $nkey, "$key passed");
	}
}

# one more special test for _path:
my @p = $h -> _path (['a', '', undef, sub {}, 'b']);
is_deeply (\@p, ['a', 'b'], 'Stupid array ok');

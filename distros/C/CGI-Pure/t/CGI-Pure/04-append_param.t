# Pragmas.
use strict;
use warnings;

# Modules.
use CGI::Pure;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CGI::Pure->new;
my @ret = $obj->append_param('param', 'foo');
is_deeply(
	\@ret,
	[
		'foo',
	],
);

# Test.
@ret = $obj->append_param('param', 'bar');
is_deeply(
	\@ret,
	[
		'bar',
		'foo',
	],
);

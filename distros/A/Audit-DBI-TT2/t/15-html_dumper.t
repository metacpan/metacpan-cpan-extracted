#!perl -T

use strict;
use warnings;

use Audit::DBI::TT2;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 2;


can_ok(
	'Audit::DBI::TT2',
	'html_dumper',
);

my $tests =
[
	{
		name     => 'Dump hashref.',
		input    =>
		{
			'test1' => 'value1',
			'test2' => 'value2',
		},
		expected => '{&nbsp;test1&nbsp;=&gt;&nbsp;&quot;value1&quot;,&nbsp;test2&nbsp;=&gt;&nbsp;&quot;value2&quot;&nbsp;}',
	},
];

foreach my $test ( @$tests )
{
	is(
		Audit::DBI::TT2::html_dumper( $test->{'input'} ),
		$test->{'expected'},
		$test->{'name'},
	);
}


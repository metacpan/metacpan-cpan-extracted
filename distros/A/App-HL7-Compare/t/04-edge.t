use v5.10;
use strict;
use warnings;

use Test::More;
use App::HL7::Compare;

subtest 'should handle empty components' => sub {
	my $comparer = App::HL7::Compare->new(
		files => [
			\(join "\n", 'MSH|^~\&', 'PID|a|^^^|b'),
			\(join "\n", 'MSH|^~\&', 'PID|a|^^^|b'),
		],
	);

	my $comparison = $comparer->compare_stringify;
	is $comparison, join(
		"\n",
	);
};

subtest 'segments should be in an intuitive order' => sub {
	my $comparer = App::HL7::Compare->new(
		files => [
			\(join "\n", 'MSH|^~\&', 'PID|a', 'ORC|a', 'OBR|a', 'OBX|a'),
			\(join "\n", 'MSH|^~\&', 'PID|a', 'NTE|a'),
		],
	);

	my $comparison = $comparer->compare_stringify;
	is $comparison, join(
		"\n",
		'ORC.1[1]: a => (empty)',
		'NTE.1[1]: (empty) => a',
		'OBR.1[1]: a => (empty)',
		'OBX.1[1]: a => (empty)',
	);
};

done_testing;


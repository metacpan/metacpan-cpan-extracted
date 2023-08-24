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

done_testing;


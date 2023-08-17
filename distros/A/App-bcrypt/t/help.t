use v5.10;
use experimental qw(signatures);

use Test::More;

require './t/lib/common.pl';

my $help_pattern = qr|^SYNOPSIS|m;

subtest 'help' => sub {
	my @tuples = (
		 ['--help'], ['-h'],
		 ['--help', '--quiet'], ['-h', '--quiet'],
		 ['--help', '--debug'], ['-h', '--debug'],
		 );

	foreach my $tuple ( @tuples ) {
		subtest join( " ", $tuple->@* ) => sub {
			my $result = run_command( args => $tuple );
			like $result->{output}, $help_pattern, 'perl version does not appear';
			is $result->{exit}, 0, 'Exit code is 0';
			};
		}
	};

done_testing();

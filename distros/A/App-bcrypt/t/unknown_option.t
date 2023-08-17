use v5.10;
use experimental qw(signatures);

use IPC::Open3;
use Test::More;

require './t/lib/common.pl';

my $error_pattern = qr|^SYNOPSIS|m;

subtest 'help' => sub {
	my @tuples = (
		 ['--not-there'], ['-d', '-x'],
		 );

	foreach my $tuple ( @tuples ) {
		subtest join( " ", $tuple->@* ) => sub {
			my $result = run_command( args => $tuple );
			like $result->{error}, qr/Unknown option/, 'gets unknown option warning';
			is $result->{exit}, 2, 'Exit code is 2';
			};
		}
	};

done_testing();

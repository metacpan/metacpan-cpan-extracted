use v5.10;
use experimental qw(signatures);

use Test::More;

require './t/lib/common.pl';

my $perl_version_pattern = qr|perl \s+ v5\.\d+\.\d+ \s+ at|xa;
my $help_pattern = qr|^SYNOPSIS|m;

subtest 'version without debugging' => sub {
	my @tuples = (
		['--version'], ['-v'],
		['--version', '--help' ], ['--version', '-h' ],
		['-v', '--help' ], ['-v', '-h' ],
		['--version', '--quiet' ], ['--version', '-q' ],
		['-v', '--quiet' ], ['-v', '-q' ],
		);
	foreach my $tuple ( @tuples ) {
		subtest join( ' ', $tuple->@* ) => sub {
			my $result = run_command( args => $tuple );
			like_version( $result->{output} );
			unlike $result->{output}, $perl_version_pattern, 'perl version does not appear';
			unlike $result->{output}, $help_pattern, 'perl help text does not appear with --version';
			is $result->{exit}, 0, 'Exit code is 0';
			};
		}
	};

subtest 'version with debugging' => sub {
	my @tuples = (
		['--version', '--debug'], ['--version', '-d'],
		['--version', '--debug', '--help'], ['--version', '-d', '--help'],
		['--version', '--debug', '--quiet'], ['--version', '-d', '--quiet'],
		['-v', '-d'], ['-v', '--debug'],
		['-v', '-d', '--quiet'], ['-v', '--debug', '--quiet'],
		);
	foreach my $tuple ( @tuples ) {
		subtest join( ' ', $tuple->@* ) => sub {
			my $result = run_command( args => $tuple );
			like_version( $result->{output} );
			like $result->{output}, $perl_version_pattern, 'perl version does not appear';
			unlike $result->{output}, $help_pattern, 'perl help text does not appear with --version';
			is $result->{exit}, 0, 'Exit code is 0';
			};
		}
	};

done_testing();

sub like_version ( $output ) {
	like $output, qr|bcrypt \s+ \d+\.\d+ \R|xa, 'Found program version';
	}


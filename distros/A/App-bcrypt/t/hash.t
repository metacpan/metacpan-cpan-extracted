use v5.10;
use experimental qw(signatures);

use Test::More;

require './t/lib/common.pl';
local %ENV;

my $password = 'Hello World';

my @options_table = (
	[ [],                            qr/^\$2b\$12\$\S+/mp ], # no options
	[ [qw(--cost 10)],               qr/^\$2b\$10\$\S+/mp ],
	[ [qw(--cost 5)],                qr/^\$2b\$05\$\S+/mp ],
	[ [qw(--salt abcdef0123456789)], qr/^\$2b\$12\$WUHhXETkKBCwKxOzLha2MOdvzFtt3s0trJ8VWDYL7AVqQCsIAkcUO/mp ],
	[ [qw(--type 2a)],               qr/^\$2a\$12\$\S+/mp ],
	);

my @env_table = (
	[ {},                                    qr/^\$2b\$12\$\S+/mp ], # no options
	[ { BCRYPT_COST => 10 },                 qr/^\$2b\$10\$\S+/mp ],
	[ { BCRYPT_COST => 5 },                  qr/^\$2b\$05\$\S+/mp ],
	[ { BCRYPT_SALT => 'abcdef0123456789' }, qr/^\$2b\$12\$WUHhXETkKBCwKxOzLha2MOdvzFtt3s0trJ8VWDYL7AVqQCsIAkcUO/mp ],
	[ { BCRYPT_TYPE => '2a' },               qr/^\$2a\$12\$\S+/mp ],
	);

foreach my $tuple ( @options_table ) {
	my( $verbose_output, $quiet_output );

	my $label = join( " ", $tuple->[0]->@* ) || 'empty';

	subtest $label => sub {
		subtest verbose => sub {
			my $result = run_command( input => $password, args => $tuple->[0] );
			like $result->{output}, $tuple->[1], 'Matches expected password pattern';
			$verbose_output = ${^MATCH};
			like $result->{output}, qr/^Reading password/m, 'Sees standard input reminder';
			is $result->{exit}, 0, 'Exits with 0';
			};
		subtest quiet => sub {
			subtest option => sub {
				local $ENV{BCRYPT_QUIET} = 0;
				my $result = run_command( input => $password, args => [ $tuple->[0]->@*, '--quiet' ] );
				quiet_test($result, $tuple->[1]);
				};
			subtest env => sub {
				local $ENV{BCRYPT_QUIET} = 1;
				my $result = run_command( input => $password, args => [ $tuple->[0]->@* ] );
				quiet_test($result, $tuple->[1]);
				};
			};
		subtest 'password arg' => sub {
			my $result = run_command( args => [ $tuple->[0]->@*, '--password', $password ] );
			unlike $result->{output}, qr/^Reading password/m, 'Sees standard input reminder';
			like $result->{output}, $tuple->[1], 'Matches expected password pattern';
			$quiet_version = ${^MATCH};
			is $result->{exit}, 0, 'Exits with 0';
			};
		is( $verbose_output, $quiet_output );
		};
	}

foreach my $tuple ( @env_table ) {
	my $label = join " ", $tuple->[0]->%*;
	subtest $label => sub {
		local %ENV = $tuple->[0]->%*;
		my $result = run_command( input => $password );
		like $result->{output}, $tuple->[1], 'Matches expected password pattern';
		is $result->{exit}, 0, 'Exits with 0';
		};
	}

sub quiet_test ( $result, $pattern ) {
	unlike $result->{output}, qr/^Reading password/m, 'Sees standard input reminder';
	like $result->{output}, $pattern, 'Matches expected password pattern';
	$quiet_version = ${^MATCH};
	is $result->{exit}, 0, 'Exits with 0';
	}

done_testing();

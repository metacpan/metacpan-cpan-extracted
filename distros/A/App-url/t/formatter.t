use v5.26;
use Mojo::Base -strict, -signatures;
use open qw(:std :utf8);
use Test::More 1;

my $program = 'blib/script/url';

subtest sanity => sub {
	my $class = 'App::url';
	use_ok( $class );
	can_ok( $class, 'run' );
	ok( -e $program, 'The program exists' );
	like( `$^X -c $program 2>&1`, qr/syntax OK/, "$program compiles" );
	};

subtest basic => sub {
	my $url = 'http://www.example.com/a/b/c?o=987&p=234';
	my $output;

	subtest newline => sub {
		chomp( $output = `$program "%n" "$url"` );
		is( $output, "\n", "Value for newline is correct" );

		chomp( $output = `$program "abc%ndef" "$url"` );
		is( $output, "abc\ndef", "Value for newline is correct" );
		};
	subtest tab => sub {
		chomp( $output = `$program "%t" "$url"` );
		is( $output, "\t", "Value for tab is correct" );

		chomp( $output = `$program "456%t987" "$url"` );
		is( $output, "456\t987", "Value for tab is correct" );
		};
	subtest percent => sub {
		chomp( $output = `$program "%%" "$url"` );
		is( $output, '%', "Value for percent is correct" );

		chomp( $output = `$program "%%" "$url"` );
		is( $output, '%', "Value for percent is correct" );
		};

	};

subtest unknown => sub {
	my $url = 'http://www.example.com/a/b/c?o=987&p=234';
	my $output;

	foreach my $specifier ( qw(X g d) ) {
		chomp( $output = `$program "%$specifier" "$url" 2>&1` );
		like( $output, qr/Invalid specifier/, "Warning for unknown specifier <$specifier>" );
		}
	};

subtest url => sub {
	my @tests = map { [ lc $_, lc $_ ] } qw(
		http://www.example.com/a/b/c
		HTTP://www.example.com/a/b/c
		https://www.example.net/a/b/c
		HtTpS://www.example.net/a/b/c
		ftp://briandfoy.github.io/a/b/c
		mailto:github.com/a/b/c
		);

	run_table( '%u', \@tests )
	};

subtest scheme => sub {
	my @tests = (
		[ qw( http://www.example.com/a/b/c    http  ) ],
		[ qw( HTTP://www.example.com/a/b/c    http  ) ],
		[ qw( https://www.example.net/a/b/c   https ) ],
		[ qw( HtTpS://www.example.net/a/b/c   https ) ],
		[ qw( ftp://briandfoy.github.io/a/b/c ftp   ) ],
		[ qw( mailto:github.com/a/b/c mailto        ) ],
		);

	run_table( '%s', \@tests )
	};

subtest host => sub {
	my @tests = (
		[ qw( http://www.example.com/a/b/c      www.example.com     ) ],
		[ qw( http://www.example.net/a/b/c      www.example.net     ) ],
		[ qw( http://briandfoy.github.io/a/b/c  briandfoy.github.io ) ],
		[ qw( http://github.com/a/b/c           github.com          ) ],
		[ qw( http://user:pass@github.com/a/b/c github.com          ) ],
		);

	run_table( '%h', \@tests )
	};

subtest ihost => sub {
	my @tests = (
		[ qw( http://www.example.com/a/b/c www.example.com     ) ],
		[ qw( http://bücher.ch/a/b/c       xn--bcher-kva.ch    ) ],
		[ qw( http://mañana.com/a/b/c      xn--maana-pta.com   ) ],
		[ qw( http://☃-⌘.com/a/b/c         xn----dqo34k.com    ) ],
		[ qw( http://éxàmple.com/a/b/c     xn--xmple-rqa5d.com ) ],
		);

	run_table( '%i', \@tests )
	};

subtest port => sub {
	my @tests = (
		[ qw( http://www.example.com/a/b/c       ) ],
		[ qw( http://www.example.net:80/a/b/c 80 ) ],
		);

	run_table( '%p', \@tests )
	};

subtest user => sub {
	my @tests = (
		[ qw( http://raptor@www.example.com/a/b/c          raptor ) ],
		[ qw( http://raptor:password@www.example.net/a/b/c raptor ) ],
		[ qw( http://briandfoy.github.io/a/b/c                    ) ],
		[ qw( mailto:joe@example.com                              ) ],
		);

	run_table( '%U', \@tests )
	};

subtest password => sub {
	my @tests = (
		[ qw( http://raptor@www.example.com/a/b/c               ) ],
		[ qw( http://raptor:adfdsa@www.example.net/a/b/c adfdsa ) ],
		[ qw( http://briandfoy.github.io/a/b/c                  ) ],
		);

	run_table( '%P', \@tests )
	};

subtest path => sub {
	no warnings qw( qw );

	my @tests = (
		[ qw( http://www.example.com/a/b/c       /a/b/c ) ],
		[ qw( https://www.example.net/g/h/d?xyz  /g/h/d ) ],
		[ qw( https://www.example.net/g/h/d#frag /g/h/d ) ],
		);

	run_table( '%a', \@tests )
	};

subtest fragment => sub {
	no warnings qw( qw );

	my @tests = (
		[ qw( http://www.example.com/a/b/c  ) ],
		[ qw( https://www.example.net/g/h/d?xyz  ) ],
		[ qw( https://www.example.net/g/h/d#frag frag ) ],
		);

	run_table( '%f', \@tests )
	};

subtest query => sub {
	no warnings qw( qw );

	my @tests = (
		[ qw( http://www.example.com/a/b/c                           ) ],
		[ qw( https://www.example.net/g/h/d?xyz          xyz         ) ],
		[ qw( https://www.example.net/g/h/d?xyz+abc      xyz+abc     ) ],
		[ qw( https://www.example.net/g/h/d?one=1&two=2  one=1&two=2 ) ],
		[ qw( https://www.example.net/g/h/d?one=1;two=2  one=1;two=2 ) ],
		[ qw( https://www.example.net/g/h/d#frag                     ) ],
		);

	run_table( '%q', \@tests )
	};

sub run_table ($template, $tests) {
	foreach my $test ( $tests->@* ) {
		chomp( my $output = `$program "$template" "$test->[0]"` );
		is( $output, $test->[1] // '', "Value for $test->[0] is correct" );
		}
	}


done_testing();

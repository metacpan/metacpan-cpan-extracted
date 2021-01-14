use Test::More 1;

my @classes = qw(Bundle::BDFOY Task::BDFOY);

foreach my $class ( @classes ) {
	BAIL_OUT() unless use_ok( $class );
	}

done_testing();

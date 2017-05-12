use Test::More 0.95;

my @classes = qw(App::Module::Lister);

foreach my $class ( @classes ) {
	print "Bail out! $class did not compile\n" unless use_ok( $class );
	}

done_testing();

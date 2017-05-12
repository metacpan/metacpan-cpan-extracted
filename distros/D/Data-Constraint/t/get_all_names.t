use Test::More 0.95;

my $class = 'Data::Constraint';
use_ok( $class );

my %names = map { $_, 1 } $class->get_all_names;

foreach my $name ( qw(defined ordinal) ) {
	ok( exists $names{$name}, "Found constraint named [$name]" );
	}

done_testing();

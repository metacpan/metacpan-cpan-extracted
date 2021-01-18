use Test::More 0.95;

my $class = 'Data::Constraint';
use_ok( $class );

$class->add_constraint(
       'defined',
       'run'         => sub { defined $_[1] },
       'description' => 'True if the value is defined',
       );

$class->add_constraint(
       'ordinal',
       'run'         => sub { $_[1] =~ /^\d+\z/ },
       'description' => 'True if the value is has only digits',
       );

$class->add_constraint(
       'test',
       'run' => sub { 1 },
       );

my %names = map { $_, 1 } $class->get_all_names;

foreach my $name ( qw(defined ordinal) ) {
	ok( exists $names{$name}, "Found constraint named [$name]" );
	}

done_testing();

use Apache::Session::File;

use Benchmark;

sub dotie {
	my $hashref;
	tie %$hashref, 'Apache::Session::File', undef, {Directory => '/tmp'};
}

timethis(100000, \&dotie, 'Construct 100k');


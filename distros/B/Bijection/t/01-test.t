use Test::More;
use Bijection qw/biject inverse/;

my %unique;
for (0..5000) {
	my $bi = biject($_);
	$unique{$bi}++;
	is (inverse($bi), $_, "reversable $_");
}

is (scalar keys %unique, 5001, 'all unique'); 

done_testing(5002);

1;

use Test::More;
use Bijection::XS qw/biject inverse bijection_set/;

use Data::Dumper;

my %unique;
for (0..5000) {
	my $bi = biject($_);
	$unique{$bi}++;
	my $inv = inverse($bi);
	is ($inv, $_, "reversable $_");
}

is (scalar keys %unique, 5001, 'all unique'); 

done_testing(5002);

1;

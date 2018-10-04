use Test::More;
use Bijection qw/all/;

is($Bijection::COUNT, 52, 'count ALPHA');
my %unique;
for (0..9) {
	my $bi = biject($_);
	$unique{$bi}++;
	is (inverse($bi), $_, "reversable $_");
}

my @reverse = reverse @Bijection::ALPHA;
bijection_set(@reverse);

is($Bijection::COUNT, 52, 'count ALPHA');
for (0..9) {
	my $bi = biject($_);
	$unique{$bi}++;
	is (inverse($bi), $_, "reversable $_");
}

splice @reverse, 0, 10;
bijection_set(@reverse);

is($Bijection::COUNT, 42, 'count ALPHA');
for (0..9) {
	my $bi = biject($_);
	$unique{$bi}++;
	is (inverse($bi), $_, "reversable $_");
}

is (scalar keys %unique, 30, 'all unique'); 
done_testing(34);

1;

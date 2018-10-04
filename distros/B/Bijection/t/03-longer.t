use Test::More;
use Bijection qw/all/;

my @reverse = reverse @Bijection::ALPHA;
bijection_set(900000000, @reverse);

my $bi = biject(50);
is($bi, '7P5pWV');

done_testing(1);

1;

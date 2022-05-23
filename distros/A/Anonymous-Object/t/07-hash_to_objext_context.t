use Test::More;

use Anonymous::Object;

my $num = 1;
my %hash = (
	add => sub { $num += 1 },
	minus => sub { $num -= 1 },
);


my $anon = Anonymous::Object->new()->hash_to_object_context(\%hash);

is($anon->add('thing'), 2);
is($anon->minus(), 1);

done_testing();

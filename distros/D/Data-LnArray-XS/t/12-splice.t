use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(qw/one two three four/);
ok($array->splice(0, 0, 'five'));
is($array->length, 5);

my $array = Data::LnArray::XS->new(qw/one two three four/);
ok($array->splice(0, -1, 'five'));
is($array->length, 2);
is_deeply($array, [qw/five four/]);

=pod
my $array = Data::LnArray::XS->new(qw/one two three four/);
ok($array->splice(0, -2));
is($array->length, 2);
is_deeply($array, [qw/three four/]);
=cut

done_testing;

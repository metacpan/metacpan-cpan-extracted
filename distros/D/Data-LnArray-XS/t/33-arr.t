use Test::More;

use Data::LnArray::XS qw/all/;

my $obj = arr(qw/one two three/);

is_deeply($obj, [qw/one two three/]);

done_testing;

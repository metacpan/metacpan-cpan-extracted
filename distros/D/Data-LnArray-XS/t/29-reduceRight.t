use Test::More;

use Data::LnArray::XS;

my $array = Data::LnArray::XS->new(1, 2, 3, 4);

my $reduce = $array->reduceRight(sub { $_[0] + $_[1] });

is($reduce, 10);

done_testing;

use Test::More;
use Bijection::XS qw/all/;

my @reverse = reverse qw/b c d f g h j k l m n p q r s t v w x y z B C D F G H J K L M N P Q R S T V W X Y Z 0 1 2 3 4 5 6 7 8 9/;
my $count = bijection_set(900000000, @reverse);

my $bi = biject(50);
is($bi, '7P5pWV');

done_testing(1);

1;

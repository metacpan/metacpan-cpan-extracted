use Test::More;

use Acme::Math::XS;

is add(2, 2), 4, 'Addition works';
is subtract(3, 2), 1, 'Subtraction works';

done_testing;

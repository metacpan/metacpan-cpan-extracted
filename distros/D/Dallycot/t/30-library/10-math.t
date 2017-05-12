use lib 't/lib';

use strict;
use warnings;

use Test::More;

use LibraryHelper;

require Dallycot::Library::Core;
require Dallycot::Library::Core::Streams;

uses 'http://www.dallycot.net/ns/math/1.0#',
     'http://www.dallycot.net/ns/streams/1.0#',
     'http://www.dallycot.net/ns/core/1.0#',
     'http://www.dallycot.net/ns/loc/1.0#';

BEGIN { require_ok 'Dallycot::Library::Core::Math' };

isa_ok(Dallycot::Library::Core::Math->instance, 'Dallycot::Library');

ok(Dallycot::Registry->instance->has_namespace('http://www.dallycot.net/ns/core/1.0#'), 'Core namespace is registered');

my $result;

$result = run('even?(3)');

is_deeply $result, Boolean(0), "3 is not even";

$result = run('even?(4)');

is_deeply $result, Boolean(1), "4 is even";

$result = run('odd?(3)');

is_deeply $result, Boolean(1), "3 is odd";

$result = run('odd?(4)');

is_deeply $result, Boolean(0), "4 is not odd";

$result = run("last(count-and-sum(1..9))");

is_deeply $result, Vector(Numeric(9), Numeric(45)), "count-and-sum of 1..9 is <9,45>";

$result = run("last(sum(1..9))");

is_deeply $result, Numeric(45), "Sum of 1..9 is 45";

$result = run("mean(1..9)");

isa_ok $result, 'Dallycot::Value::Stream';

$result = run("last(mean(1..9))");

is_deeply $result, Numeric(5), "Average of 1..9 is 5";

$result = run("last(min([1,-2,3,-4,5,-6,7]))");

is_deeply $result, Numeric(-6), "Minimum of [1,-2,3,-4,5,-6,7] is -6";

$result = run("last(max([1,-2,3,-4,5,-6,7]))");

is_deeply $result, Numeric(7), "Maximum of [1,-2,3,-4,5,-6,7] is 7";

$result = run("differences(1..)...'");

is_deeply $result, Numeric(1), "Difference between successive numbers is 1";

$result = run("gcd(0, 123)");

is_deeply $result, Numeric(123), "gcd(0, 123) is 123";

$result = run("gcd(234, 0)");

is_deeply $result, Numeric(234), "gcd(234, 0) is 234";

$result = run("gcd(1599, 650)");

is_deeply $result, Numeric(13), "gcd(1599, 650) is 13";

$result = run("factorial(4)");

is_deeply $result, Numeric(24), "factorial(4) should be 24";

$result = run("random(123)");

isa_ok $result, 'Dallycot::Value::Numeric';

$result = run("sin(30)");

is_deeply $result, Numeric("1/2"), "sin(30) = 1/2";

$result = run("cos(60)");

is_deeply $result, Numeric("1/2"), "cos(60) = 1/2";

$result = run("arc-tan(1)");

is_deeply $result, Numeric(45), "atan(1) = 45";

$result = run("arc-tan(1,1)");

is_deeply $result, Numeric(45), "atan(1,1) = 45";

$result = run("arc-tan(-1,-1)");

is_deeply $result, Numeric(45-180), "atan(-1,-1) = -135";

$result = run("tan(45)");

is_deeply $result, Numeric(1), "tan(45) = 1";

$result = run("odds...'");

is_deeply $result, Numeric(3), "Second odd is 3";

$result = run("odds...'");

is_deeply $result, Numeric(3), "Second odd is 3 with semi-range";

$result = run("primes'");

is_deeply $result, Numeric(1), "1 is the first prime";

$result = run("primes...'");

is_deeply $result, Numeric(2), "2 is the second prime";

$result = run("primes......'");

is_deeply $result, Numeric(3), "3 is the third prime";

$result = run("primes.........");

isa_ok $result, 'Dallycot::Value::Stream';

$result = run("primes.........'");

is_deeply $result, Numeric(5), "5 is the 4th prime";

$result = run("primes............");

isa_ok $result, 'Dallycot::Value::Stream';

$result = run("primes............'");

is_deeply $result, Numeric(7), "7 is the 5th prime";

$result = run("primes... ... ... ... ... ... ...'");

is_deeply $result, Numeric(17), "17 is the 8th prime";

$result = run("fibonacci-sequence... ... ... ... ...'");

is_deeply $result, Numeric(8), "6th Fibonacci is 8";

$result = run("fibonacci-sequence[8]");

is_deeply $result, Numeric(21), "8th Fibonacci is 21";

$result = run("fibonacci(8)");

is_deeply $result, Numeric(21), "8th Fibonacci is 21";

$result = run("factorials[2]");

is_deeply $result, Numeric(2), "2! is 2";

$result = run("factorials[4]");

is_deeply $result, Numeric(24), "4! is 24";

$result = run("prime-pairs");

isa_ok $result, "Dallycot::Value::Stream";

$result = run("prime-pairs[1]");

is_deeply $result, Vector(Numeric(1), Numeric(2)), "First two primes are 1,2";

$result = run("prime-pairs[4]");

is_deeply $result, Vector(Numeric(5), Numeric(7)), "Fourth two primes are 5,7";

$result = run("twin-primes");

isa_ok $result, "Dallycot::Value::Stream";

$result = run("twin-primes[1]");

is_deeply $result, Vector(Numeric(3), Numeric(5)), "First twin primes are 3, 5";

# # 1 2 3 5 7 11 13 17 19 23 29 31
# #     .....  ...   ...      ...
# #      1 2    3     4        5

$result = run("twin-primes[5]");

is_deeply $result, Vector(Numeric(29), Numeric(31)), "Fifth pair is <29,31>";

done_testing();

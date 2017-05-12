
use Test::More;

use Acme::TestDist::Cpp::EUMM::EUCppGuess;
ok(1); # If we made it this far, we're ok.

is(Acme::TestDist::Cpp::EUMM::EUCppGuess::return_one(),1);

done_testing();


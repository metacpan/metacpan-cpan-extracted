use Test::More tests => 1;
use FindBin;

BEGIN {
    use_ok('Alien::LibANN');
}

diag("Testing Alien::LibANN $Alien::LibANN::VERSION");

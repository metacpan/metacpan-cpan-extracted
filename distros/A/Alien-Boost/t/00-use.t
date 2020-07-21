use Test::More tests => 1;
use FindBin;

BEGIN {
    use_ok('Alien::Boost');
}

diag("Testing Alien::Boost $Alien::Boost::VERSION");

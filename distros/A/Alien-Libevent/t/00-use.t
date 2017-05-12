use Test::More tests => 1;
use FindBin;

BEGIN {
    use_ok('Alien::Libevent');
}

diag("Testing Alien::Libevent $Alien::Libevent::VERSION");

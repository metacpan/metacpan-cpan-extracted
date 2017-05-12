use Test::More tests => 1;
use FindBin;

BEGIN {
    use_ok('Alien::Gearman');
}

diag("Testing Alien::Gearman $Alien::Gearman::VERSION");
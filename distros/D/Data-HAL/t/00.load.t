use strictures;
use Test::More import => [qw(diag done_testing use_ok)];

BEGIN {
    use_ok('Data::HAL');
    use_ok('Data::HAL::Link');
    use_ok('Data::HAL::URI');
    use_ok('Data::HAL::URI::NamespaceMap');
}

diag('Testing Data::HAL ' . Data::HAL->VERSION);

done_testing;

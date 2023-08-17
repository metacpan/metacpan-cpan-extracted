#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Blockchain::Ethereum::Transaction');
    use_ok('Blockchain::Ethereum::Transaction::Legacy');
    use_ok('Blockchain::Ethereum::Transaction::EIP1559');
}

done_testing;

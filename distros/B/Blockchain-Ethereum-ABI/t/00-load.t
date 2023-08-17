#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN {
    use_ok('Blockchain::Ethereum::ABI');
    use_ok('Blockchain::Ethereum::ABI::Encoder');
    use_ok('Blockchain::Ethereum::ABI::Decoder');
    use_ok('Blockchain::Ethereum::ABI::Type');
    use_ok('Blockchain::Ethereum::ABI::TypeRole');
    use_ok('Blockchain::Ethereum::ABI::Type::Address');
    use_ok('Blockchain::Ethereum::ABI::Type::Int');
    use_ok('Blockchain::Ethereum::ABI::Type::Array');
    use_ok('Blockchain::Ethereum::ABI::Type::Tuple');
    use_ok('Blockchain::Ethereum::ABI::Type::String');
    use_ok('Blockchain::Ethereum::ABI::Type::Bytes');
}

done_testing;

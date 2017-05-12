use strict;
use Test::More tests => 1;

BEGIN { use_ok 'Data::TxnBuffer' }

diag "Testing Data::TxnBuffer/$Data::TxnBuffer::VERSION";
diag "Backend: ", $Data::TxnBuffer::BACKEND;



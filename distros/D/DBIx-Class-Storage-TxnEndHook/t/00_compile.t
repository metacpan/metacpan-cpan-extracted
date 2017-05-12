use strict;
use Test::More;

use_ok $_ for qw(
    DBIx::Class::Storage::TxnEndHook
    DBIx::Class::Schema::TxnEndHook
);

done_testing;


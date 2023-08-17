use Test::More;

use DBIx::SQLstate qw/:token/;

is( sqlstate_token("0100F"),
    'StatementTooLongForInformationSchema',
    "Got the right token for an exisitng SQL-state code"
);

is( sqlstate_class_token("0100F"),
    'Warning',
    "Got the right class token for an exisitng SQL-state code"
);

is( sqlstate_default_token(),
    'UnknownSQLstate',
    "Got the default token without an exisitng SQL-state code"
);

done_testing;

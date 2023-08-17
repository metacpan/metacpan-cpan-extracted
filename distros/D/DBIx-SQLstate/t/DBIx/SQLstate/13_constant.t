use Test::More;

use DBIx::SQLstate qw/:const/;

is( sqlstate_const("0100F"),
    'SQLSTATE_STATEMENT_TOO_LONG_FOR_INFORMATION_SCHEMA',
    "Got the right constant for an exisitng SQL-state code"
);

is( sqlstate_class_const("0100F"),
    'SQLSTATE_WARNING',
    "Got the right class constant for an exisitng SQL-state code"
);

is( sqlstate_default_const(),
    'SQLSTATE_UNKNOWN_SQL_STATE',
    "Got the default constant without an exisitng SQL-state code"
);

done_testing;

use Test::More;

use DBIx::SQLstate qw/:message/;

is( uc(sqlstate_message("0100F")),
    uc('statement too long for information schema'),
    "Got the right message for an exisitng SQL-state code"
);

is( uc(sqlstate_class_message("0100F")),
    uc('warning'),
    "Got the right class message for an exisitng SQL-state code"
);

is( uc(sqlstate_default_message()),
    uc('Unknown SQL-state'),
    "Got the default message without an exisitng SQL-state code"
);

done_testing;

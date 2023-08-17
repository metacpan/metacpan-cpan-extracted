use Test::More;

use DBIx::SQLstate;

is( uc(DBIx::SQLstate->message("01002")),
    uc('disconnect error'),
    "Got the right message for an exisitng SQL-state code"
);

is( uc(DBIx::SQLstate->message("01XXX")),
    uc('warning'),
    "Got the class message for a non exisitng SQL-state code"
);

is( uc(DBIx::SQLstate->message("XXXXX")),
    uc('Unknown SQL-state'),
    "Got the default message in any other case"
);

done_testing;

__END__

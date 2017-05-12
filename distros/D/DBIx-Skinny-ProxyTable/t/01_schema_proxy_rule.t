use lib 't';
use Test::More;

BEGIN {
    eval "use DBD::SQLite";
    plan skip_all => "DBD::SQLite is not installed. skip testing" if $@;
}

BEGIN { use_ok('Mock::Basic'); }

done_testing();

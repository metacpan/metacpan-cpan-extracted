use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use QDB::Installs qw/run_per_install/;             # before any Test2 tools: it loads Test2::IPC
use Test2::Tools::Basic qw/done_testing/;          # not Test2::V0: QuickDB.pm imports V0 into main in the child

# The parent process must not load DBIx::QuickDB or Test2::Tools::QuickDB;
# each install's body runs in a forked child that sets $PATH first. See
# t/lib/QDB/Installs.pm.
run_per_install(SQLite => sub {
    our $DRIVERS = ['SQLite'];
    do "$Bin/QuickDB.pm";
    die $@ if $@;
});

done_testing;

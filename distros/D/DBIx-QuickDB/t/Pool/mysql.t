use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use QDB::Installs qw/run_per_install/;    # before Test2::V0: it loads Test2::IPC
use Test2::V0;

# The parent process must not load DBIx::QuickDB or Test2::Tools::QuickDB;
# each install's body runs in a forked child that sets $PATH first. See
# t/lib/QDB/Installs.pm.
run_per_install(MySQL => sub {
    # Contaminate the env vars the driver should mask, to prove it does.
    QDB::Installs::contaminate_env('MySQL');

    require Test2::Tools::QuickDB;
    Test2::Tools::QuickDB::skipall_unless_can_db('MySQL');

    no strict 'refs';
    *{"main::DRIVER"} = sub() { 'MySQL' };

    require "$Bin/Pool.pm";
});

done_testing;

use Test2::V0 -target => 'DBIx::QuickDB';
use Test2::Tools::QuickDB;

my $driver = skipall_unless_can_db(drivers => $main::DRIVERS);
diag("Using driver '$driver'");

# DBIx::QuickDB->import builds (and starts) a server immediately. A host out of
# System V IPC cannot start one; that is an environment limit, not a fault here,
# so skip the whole test rather than failing -- mirrors get_db(). Any other
# error is real and is rethrown. The eval must wrap the import call inline (not
# via a helper sub) so import() still sees the correct caller package and
# installs db_a() there.
sub resource_skip_or_rethrow {
    my ($err) = @_;
    skipall_on_resource_error($err);
    die $err;
}

eval { $CLASS->import('db_a' => {driver => $driver}); 1 }
    or resource_skip_or_rethrow($@);

my $check = $driver;
isa_ok(db_a(), [$check], "imported an instance");

{
    package XXX;
    eval { $main::CLASS->import('db_a' => {driver => $driver}); 1 }
        or main::resource_skip_or_rethrow($@);
    main::ref_is(db_a(), main::db_a(), "Cached and re-used db_a by name");

    package YYY;
    eval { $main::CLASS->import('db_a' => {driver => $driver, nocache => 1}); 1 }
        or main::resource_skip_or_rethrow($@);
    main::ref_is_not(db_a(), main::db_a(), "New db");
}

done_testing;

1;

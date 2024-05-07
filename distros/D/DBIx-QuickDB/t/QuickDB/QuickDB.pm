use Test2::V0 -target => 'DBIx::QuickDB';
use Test2::Tools::QuickDB;

my $driver = skipall_unless_can_db(drivers => $main::DRIVERS);
diag("Using driver '$driver'");

$CLASS->import('db_a' => {driver => $driver});
my $check = $driver =~ m/MySQL$/ ? "${driver}::Base" : $driver;
isa_ok(db_a(), [$check], "imported an instance");

{
    package XXX;
    $main::CLASS->import('db_a' => {driver => $driver});
    main::ref_is(db_a(), main::db_a(), "Cached and re-used db_a by name");
#
#    package YYY;
#    $main::CLASS->import('db_a' => {driver => $driver, nocache => 1});
#    main::ref_is_not(db_a(), main::db_a(), "New db");
}

done_testing;

1;

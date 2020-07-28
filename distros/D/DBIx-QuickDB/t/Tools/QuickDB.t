use Test2::V0 -target => 'Test2::Tools::QuickDB';
use Test2::Tools::QuickDB qw/get_db_or_skipall get_db skipall_unless_can_db/;

use Test2::API qw/intercept/;

imported_ok qw/get_db_or_skipall get_db skipall_unless_can_db/;

subtest skipall_unless_can_db => sub {
    my $events = intercept { skipall_unless_can_db(drivers => ['Fake DB1', 'Fake DB2']) };
    my ($plan) = @$events;
    like($plan->facet_data->{plan}, {max => FDNE(), details => 'no db driver is viable', skip => 1}, "Would have skipped");

    skipall_unless_can_db();
    ok(1, "We can use a db");
};

subtest get_db => sub {
    skipall_unless_can_db();
    my $db = get_db;
    isa_ok($db, ['DBIx::QuickDB::Driver'], "Got the db");
};

subtest get_db_or_skipall => sub {
    my $events = intercept { get_db_or_skipall foo => {drivers => ['Fake DB1', 'Fake DB2']} };
    my ($plan) = @$events;
    like($plan->facet_data->{plan}, {max => FDNE(), details => 'no db driver is viable', skip => 1}, "Would have skipped");

    my $db = get_db_or_skipall;
    isa_ok($db, ['DBIx::QuickDB::Driver'], "Got the db");
};

done_testing;

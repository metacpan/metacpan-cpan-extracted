# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Type/DateTime.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    use DateTime;

    my $ann = $orm->insert(
        users => {
            name    => 'Ann',
            created => DateTime->new(
                year  => 2024,
                month => 2,
                day   => 3,
            ),
        },
    );

    my $when = $ann->field('created');             # date and timestamp fields are typed by default
    my $year = $when->datetime_ref->year;          # 2024
    my $next = $when->datetime->add(days => 1);    # a copy, so $when is unchanged
    $ann->update({created => $next});

    is($year,                      2024,                  "a timestamp inflates to a DateTime");
    is("$when",                    '2024-02-03T00:00:00', "add leaves the value alone");
    is($ann->raw_field('created'), '2024-02-04 00:00:00', "and its new value is written back");
};

done_testing;

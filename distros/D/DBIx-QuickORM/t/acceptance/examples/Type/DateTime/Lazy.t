# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Type/DateTime/Lazy.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DateTime;
use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });
    my $row = $orm->insert(users => {name => 'Ann', created => '2024-02-03 04:05:06'});

    # SYNOPSIS
    my $at   = $row->field('created');     # nothing parsed yet
    my $year = $at->datetime_ref->year;    # builds the DateTime once
    my $text = "$at";                      # 2024-02-03T04:05:06
    my $soon = $at < DateTime->now;        # compares the dates

    is($year, 2024,                  "datetime_ref reads the DateTime");
    is($text, '2024-02-03T04:05:06', "stringifies to ISO 8601");
    ok($soon, "compares with a DateTime");

    # DESCRIPTION
    {
        my $at = $row->field('created');

        my $year = $at->datetime_ref->year;          # read: no copy
        my $next = $at->datetime->add(days => 1);    # change a copy
        $row->update({created => $next});

        is($year,                      2024,                  "read without a copy");
        is("$at",                      '2024-02-03T04:05:06', "the copy's change leaves the value alone");
        is($row->raw_field('created'), '2024-02-04 04:05:06', "and is written back");
    }
};

done_testing;

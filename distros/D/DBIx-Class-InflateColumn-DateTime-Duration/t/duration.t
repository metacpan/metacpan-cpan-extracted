#!perl -wT
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use lib 'lib';
    use DBIC::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 27;
    };

    use_ok('DateTime::Duration');
};


my $schema = DBIC::Test->init_schema;


## Test Resources, which has no class level options set
{
    my $events = $schema->resultset('Event')->search;

    is($events->count, 5);

    ## load em up and check codes/formats/values
    my $event = $events->next;
    isa_ok($event, 'DBIC::TestSchema::Event');
    isa_ok($event->length, 'DateTime::Duration');
    is($event->length->delta_months, 51, 'delta_months');
    is($event->length->delta_days, 14, 'delta_days');

    $event = $events->next;
    isa_ok($event, 'DBIC::TestSchema::Event');
    isa_ok($event->length, 'DateTime::Duration');
    is($event->length->delta_days, 57, 'delta_days');
    is($event->length->delta_minutes, 814, 'delta_minutes');
    is($event->length->delta_seconds, 6, 'delta_seconds');

    $event = $events->next;
    isa_ok($event, 'DBIC::TestSchema::Event');
    isa_ok($event->length, 'DateTime::Duration');
    is($event->length->delta_minutes, 90, 'delta_minutes');

    $event = $events->next;
    isa_ok($event, 'DBIC::TestSchema::Event');
    isa_ok($event->length, 'DateTime::Duration');
    is($event->length->delta_minutes, 123, 'delta_minutes');
    is($event->length->delta_seconds, 59, 'delta_seconds');

    $event = $events->next;
    isa_ok($event, 'DBIC::TestSchema::Event');
    isa_ok($event->length, 'DateTime::Duration');
    is($event->length->delta_seconds, 9, 'delta_seconds');
    is($event->length->delta_nanoseconds, 580_000_000, 'delta_nanoseconds');

    ## create with objects/deflate
    my $row = $schema->resultset('Event')->create({
        label  => q{John Lennon's age},
        length => DateTime::Duration->new(years => 40, days => 60),
    });

    is($row->get_column('length'), 'P40Y0M60DT0H0M0S', 'serialiser');

    isa_ok($row, 'DBIC::TestSchema::Event');
    isa_ok($row->length, 'DateTime::Duration');
    is($row->length->delta_months, 480, 'delta_months');
    is($row->length->delta_days, 60, 'delta_days');

};


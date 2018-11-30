use strict;
use warnings;
use 5.20.0;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use lib 't/lib';
use DateTime;
use Module::Load;
use TestFor::DBIx::Class::Smooth::Schema;
use experimental qw/postderef/;

my $schema = TestFor::DBIx::Class::Smooth::Schema->connect();

if($ENV{'DBIC_SMOOTH_SCHEMA'}) {
    load $ENV{'DBIC_SMOOTH_SCHEMA'};
    $schema = $ENV{'DBIC_SMOOTH_SCHEMA'}->connect();
}
else {
    isa_ok $schema, 'DBIx::Class::Schema';
    done_testing;
    exit;
}

isa_ok $schema, 'DBIx::Class::Schema';

my $tests = [
    {
        test => q{ $schema->resultset('Zone')->_smooth__prepare_for_filter(name__not_in => ['Silmarillion']) },
        result => ['me.name' => { -not_in => ['Silmarillion']}],
    },
    {
        test => q{ $schema->resultset('Zone')->_smooth__prepare_for_filter(created_date_time__year => 2005) },
        result => [ \['EXTRACT(YEAR FROM me.created_date_time) =  ? ', 2005] ],
    },
    {
        test => q{ $schema->resultset('Zone')->_smooth__prepare_for_filter("created_date_time__datepart(second)" => 59) },
        result => [ \['EXTRACT(SECOND FROM me.created_date_time) =  ? ', 59] ],
    },
    {
        test => q{ $schema->resultset('Zone')->_smooth__prepare_for_filter("created_date_time__datepart(badpart)" => 59) },
        result => undef,
    },
    {
        test => q{ $schema->resultset('Zone')->_smooth__prepare_for_filter("created_date_time__datepart(this, is, bad)" => 59) },
        result => undef,
    },
    {
        test => q{ $schema->resultset('Zone')->_smooth__prepare_for_filter("name__substring(2, 9)__like" => '%anta Clau%') },
        result => [ \['BINARY SUBSTRING(me.name, 2, 9) LIKE  ? ', '%anta Clau%'] ],
    },
];

for my $test (@{ $tests }) {
    next if !length $test->{'test'};
    my $got = eval($test->{'test'});
    is_deeply $got, $test->{'result'}, $test->{'test'} or diag explain $got;
}

done_testing;

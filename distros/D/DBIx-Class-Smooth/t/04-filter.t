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

my $schema;

if($ENV{'DBIC_SMOOTH_SCHEMA'}) {
    load $ENV{'DBIC_SMOOTH_SCHEMA'};
    $schema = $ENV{'DBIC_SMOOTH_SCHEMA'}->connect();
}
else {
    $schema = TestFor::DBIx::Class::Smooth::Schema->connect();
}

isa_ok $schema, 'DBIx::Class::Schema';

my $tests = [
    {
        test => $schema->Book->except_titles('Silmarillion'),
        result => ['me.title' => { -not_in => ['Silmarillion']}],
    },
];

for my $test (@{ $tests }) {
    my $got = $test->{'test'};
    is_deeply $got, $test->{'result'} or diag explain $got;
}

done_testing;

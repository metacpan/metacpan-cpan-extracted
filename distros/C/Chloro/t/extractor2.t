use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

BEGIN {
    plan skip_all => 'These tests require DateTime.pm'
        unless eval { require DateTime };
}

use Chloro::Test::DateFromStr;

my $form = Chloro::Test::DateFromStr->new();

{
    my $set = $form->process(
        params => {
            year  => 2011,
            month => 3,
            day   => 31,
        }
    );

    my $results = $set->results_as_hash();

    isa_ok( $results->{date}, 'DateTime', 'date field result' );

    is_deeply(
        $results,
        { date => '2011-03-31T00:00:00' },
        'date is extracted from y/m/d fields and returned as DateTime object'
    );
}

done_testing();

use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Chloro::Test::CompoundDate;

my $form = Chloro::Test::CompoundDate->new();

{
    my $result_set = $form->process(
        params => {
            year  => 2011,
            month => 3,
            day   => 31,
        }
    );

    is_deeply(
        $result_set->results_as_hash(),
        { date => '2011-3-31' },
        'date is extracted from y/m/d fields'
    );
}

done_testing();

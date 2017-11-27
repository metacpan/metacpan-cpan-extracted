use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';

use Chloro::Test::Default;

my $form = Chloro::Test::Default->new();

{
    my %params = (
        baz_id       => [ 'key1', 'key2' ],
        'baz.key1.x' => 6,
        'baz.key2.x' => 12,
    );

    my $result_set = $form->process( params => \%params );

    is_deeply(
        $result_set->results_as_hash(), {
            foo => 42,
            bar => [],
            baz => {
                key1 => {
                    x => 6,
                    y => [ \%params, 'baz.key1' ],
                },
                key2 => {
                    x => 12,
                    y => [ \%params, 'baz.key2' ],
                },
            },
            baz_id => [ 'key1', 'key2' ],
        },
        'defaults generate expected values'
    );
}

done_testing();

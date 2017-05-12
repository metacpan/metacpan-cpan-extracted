use strict;
use warnings;

use Test::More 0.88;

{
    package Form;

    use Moose;
    use Chloro;

    use Chloro::Types qw( Bool );

    field boolean => (
        isa      => Bool,
        required => 1,
    );
}

{
    my $form = Form->new();

    my $set = $form->process( params => {} );

    ok( $set->is_valid(), 'missing boolean param is treated as false' );

    is_deeply(
        $set->results_as_hash(),
        { boolean => 0 },
        'boolean is false when not present params'
    );
}

done_testing();

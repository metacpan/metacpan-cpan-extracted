use strict;
use warnings;

use Test::More 0.88;

{
    package Form;

    use Moose;
    use namespace::autoclean;

    use Chloro;

    use Chloro::Types qw( Bool );

    field boolean => (
        isa      => Bool,
        required => 1,
    );

    __PACKAGE__->meta()->make_immutable;
}

{
    my $form = Form->new();

    my $result_set = $form->process( params => {} );

    ok(
        $result_set->is_valid(),
        'missing boolean param is treated as false'
    );

    is_deeply(
        $result_set->results_as_hash(),
        { boolean => 0 },
        'boolean is false when not present params'
    );
}

done_testing();

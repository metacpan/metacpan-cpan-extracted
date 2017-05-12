use Test::More tests => 3;

use Data::Pipeline::Iterator;
use Data::Pipeline::Adapter::Array;
use Data::Pipeline::Action::Count;
use Data::Pipeline::Action::Truncate;

my $iterator = Data::Pipeline::Iterator -> new(
    source => Data::Pipeline::Adapter::Array -> new(
        array => [ 1 .. 10 ]
    )
);

$action = Data::Pipeline::Action::Count -> new -> transform(
    Data::Pipeline::Action::Truncate -> new( length => 5 ) -> transform(
        $iterator
    )
);

ok( !$action -> finished );
is( $action -> next -> {'count'}, 5 );
ok( $action -> finished );

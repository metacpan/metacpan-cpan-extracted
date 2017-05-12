use Test::More tests => 3;

use Data::Pipeline::Iterator;
use Data::Pipeline::Adapter::Array;
use Data::Pipeline::Action::Count;

my $iterator = Data::Pipeline::Iterator -> new(
    source => Data::Pipeline::Adapter::Array -> new(
        array => [ 1 .. 10 ]
    )
);

my $action = Data::Pipeline::Action::Count -> new -> transform( $iterator );

ok( !$action -> finished );
is( $action -> next -> {'count'}, 10 );
ok( $action -> finished );

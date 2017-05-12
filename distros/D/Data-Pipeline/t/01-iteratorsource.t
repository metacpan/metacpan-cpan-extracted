use Test::More tests => 18;

use Data::Pipeline::Iterator::Source;

my @things = (1..10);
my $source = Data::Pipeline::Iterator::Source -> new(
    has_next => sub { scalar(@things) > 0 },
    get_next => sub { shift @things }
);

my $id = '195';

my $other_id = '394';

$source -> register($id);
$source -> register($other_id);

is( $source -> next( $id ), 1 );
is( $source -> next( $id ), 2 );
is( $source -> next( $id ), 3 );
is( $source -> next( $id ), 4 );

is( scalar(@things), 6 );

is( $source -> next( $other_id ), 1 );
is( $source -> next( $other_id ), 2 );
is( $source -> next( $other_id ), 3 );
is( $source -> next( $other_id ), 4 );

is( scalar(@things), 6 );

is( $source -> next( $id ), 5 );
is( $source -> next( $id ), 6 );
is( $source -> next( $id ), 7 );
is( $source -> next( $id ), 8 );
is( $source -> next( $id ), 9 );
is( $source -> next( $id ), 10 );
ok( $source -> finished( $id ) );
ok(!$source -> finished( $other_id ) );

use Test::More;
use Beagle::Model::Review;

my $review = Beagle::Model::Review->new();

isa_ok( $review, 'Beagle::Model::Review' );
isa_ok( $review, 'Beagle::Model::Entry' );

for my $attr (qw/isbn published publisher author translator link price location/) {
    can_ok( $review, "work_$attr" );
}

for my $method (qw/work_cover/) {
    can_ok( $review, $method );
}

done_testing();

use Test::More;
use Beagle::Model::Comment;

my $comment = Beagle::Model::Comment->new();

isa_ok( $comment, 'Beagle::Model::Comment' );
isa_ok( $comment, 'Beagle::Model::Entry' );

for my $attr (qw/parent_id/) {
    can_ok( $comment, $attr );
}

done_testing();

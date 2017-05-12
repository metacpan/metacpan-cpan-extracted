use Test::More;
use Beagle::Model::Article;

my $article = Beagle::Model::Article->new();

isa_ok( $article, 'Beagle::Model::Article' );
isa_ok( $article, 'Beagle::Model::Entry' );
for my $attr (qw/title tags/) {
    can_ok( $article, $attr );
}

done_testing();

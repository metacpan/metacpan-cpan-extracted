use Test::More;
use Acme::MetaSyntactic::cpanauthors;

my @categories = sort Acme::MetaSyntactic::cpanauthors->categories;

plan tests => 2 * @categories;

for my $category (@categories) {
    is( $category, lc $category, "$category is in lowercase" );
    my $acme = Acme::MetaSyntactic::cpanauthors->new( category => $category );
    is_deeply(
        [ sort $acme->name(0) ],
        [ map uc, sort $acme->name(0) ],
        "names in $category are all in uppercase"
    );
}

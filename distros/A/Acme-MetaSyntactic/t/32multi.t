use Test::More;
use strict;
use Acme::MetaSyntactic;

END {
    my %tests = (
        ':all' => [
            qw( grinder lacravate echo book jq dm stomakc maddingue
                arhuman davorg clkao dha)
        ],
        'fr' => [
            qw( grinder lacravate echo book jq dm stomakc maddingue arhuman )
        ],
        'fr/paris'         => [qw( grinder lacravate echo book )],
        'fr/lyon'          => [qw( book jq dm stomakc )],
        'fr/lyon/perrache' => [qw( book )],
        'fr/lyon/ailleurs' => [qw( jq dm stomakc )],
        'fr/marseille'     => [qw( maddingue arhuman )],
        'uk'               => [qw( davorg clkao )],
        'uk/london'        => [qw( davorg clkao )],
        'us'               => ['dha'],
        'us/new-york'      => ['dha'],
        'mars'             => [],
    );

    plan tests => ( 2 + keys %tests ) * 4 + 8;

    my @categories = Acme::MetaSyntactic::mongers->categories();
    is_deeply(
        [ sort @categories ],
        [ grep { $_ ne ':all' } sort keys %tests ],
        "All categories (class)"
    );

    @categories = Acme::MetaSyntactic::mongers->new()->categories();
    is_deeply(
        [ sort @categories ],
        [ grep { $_ ne ':all' } sort keys %tests ],
        "All categories (instances)"
    );

    for my $args ( [], map { [ category => $_ ] } @categories, ':all', 'zz' ) {
        my $meta = Acme::MetaSyntactic::mongers->new(@$args);
        my $category = $args->[1] || 'fr/lyon';
        $category = 'fr/lyon'
            if $category eq 'zz';    # check fallback to default

        my ( $one, $four ) = ( 1, 4 );
        ( $one, $four ) = ( 0, 0 ) if $category eq 'mars';    # empty list
        my @mongers = $meta->name();
        is( $meta->category(), $category, "category() is $category" );
        is( @mongers, $one, "Single item ($one $category)" );
        @mongers = $meta->name(4);
        is( @mongers, $four, "Four items ($four $category)" );

        @mongers = sort $meta->name(0);
        is_deeply(
            \@mongers,
            [ sort @{ $tests{$category} } ],
            "All items ($category)"
        );
    }

    # test has_category (class)
    ok( Acme::MetaSyntactic::mongers->has_category( 'fr' ), "class has 'fr'" );
    ok( Acme::MetaSyntactic::mongers->has_category( 'fr/lyon' ), "class has 'fr/lyon'" );
    ok( !Acme::MetaSyntactic::mongers->has_category( 'fr/rennes' ), "class hasn't 'fr/rennes'" );

    # test has_category (instance)
    my $meta = Acme::MetaSyntactic::mongers->new( category => 'uk');
    ok( $meta->has_category('fr'), "instance has 'fr'" );
    ok( $meta->has_category('fr/lyon'), "instance has 'fr/lyon'" );
    ok( !$meta->has_category('fr/rennes'), "instance hasn't 'fr/rennes'" );
}

package Acme::MetaSyntactic::mongers;
use Acme::MetaSyntactic::MultiList;
our @ISA = ('Acme::MetaSyntactic::MultiList');
__PACKAGE__->init();
1;

__DATA__
# default
fr/lyon
# names fr paris
grinder lacravate echo book
# names fr lyon perrache
book
# names fr lyon ailleurs
jq dm stomakc
# names fr marseille
maddingue arhuman
# names uk london
davorg clkao
# names us new-york
dha
# names mars


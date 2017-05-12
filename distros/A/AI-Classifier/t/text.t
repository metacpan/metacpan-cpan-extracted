use strict;
use warnings;

use Test::More;
use AI::Classifier::Text::Analyzer;

my $analyzer = AI::Classifier::Text::Analyzer->new();
    
ok( $analyzer, 'Analyzer created' );

my $features = {};
$analyzer->analyze( 'aaaa http://www.example.com/bbb?xx=yy&bb=cc;dd=ff', $features );
is_deeply( $features, { aaaa => 1, 'example.com' => 1, MANY_URLS => 2 } );

$features = $analyzer->analyze( 'nothing special' );
is_deeply( $features, { nothing => 1, special => 1, NO_URLS => 2 } );

my $text = 'http://www.hungry.birds! http://www.hungry.birds! http://www.hungry.birds! '
      . 'http://www.hungry.birds! http://www.hungry.birds!';
$features = {};
$analyzer->analyze_urls( \$text, $features );
is_deeply( $features, { 
        'hungry.birds!' => 5, 
        REPEATED_URLS => 2,
        MANY_URLS => 2,
    } 
);

done_testing;


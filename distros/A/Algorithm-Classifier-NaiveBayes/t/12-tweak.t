#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Storable;

use Algorithm::Classifier::NaiveBayes;

my $nb = Algorithm::Classifier::NaiveBayes->new;
$nb->train( 'spam', 'buy cheap pills' );
$nb->train( 'ham',  'meeting at noon' );
$nb->train( 'ham',  'lunch meeting' );

##
## validation
##

my $before = Storable::dclone( $nb->{'model'} );

eval { $nb->tweak(); };
like( $@, qr/No args specified/, 'tweak with no args dies' );

eval { $nb->tweak( 'derp' => 1 ); };
like( $@, qr/not a known arg/, 'tweak with a unknown arg dies' );

eval { $nb->tweak( 'ngrams' => 2 ); };
like( $@, qr/not a known arg/, 'tweak refuses data shaping settings' );

eval { $nb->tweak( 'smoothing' => 'derp' ); };
like( $@, qr/smoothing must be either/, 'tweak with a unknown smoothing dies' );

eval { $nb->tweak( 'priors' => 'derp' ); };
like( $@, qr/priors must be either/, 'tweak with a unknown priors dies' );

eval { $nb->tweak( 'alpha' => 0.5 ); };
like( $@, qr/resulting smoothing is lidstone/, 'tweak alpha while laplace dies' );

eval { $nb->tweak( 'smoothing' => 'lidstone', 'alpha' => 0 ); };
like( $@, qr/greater than 0/, 'tweak with a alpha of 0 dies' );

eval { $nb->tweak( 'smoothing' => 'lidstone', 'alpha' => 'x' ); };
like( $@, qr/greater than 0/, 'tweak with a non-numeric alpha dies' );

is_deeply( $nb->{'model'}, $before, 'model unchanged after failed tweaks' );

##
## smoothing and alpha
##

$nb->tweak( 'smoothing' => 'lidstone', 'alpha' => 0.5 );
is( $nb->{'model'}{'smoothing'}, 'lidstone', 'tweak changes smoothing' );
is( $nb->{'model'}{'alpha'},     0.5,        'tweak changes alpha' );

# the new alpha is actually used when scoring... one class, two trained
# tokens, so a unseen token scores log( (0 + 0.5) / (2 + 0.5 * 2) )
my $scored = Algorithm::Classifier::NaiveBayes->new;
$scored->train( 'only', 'aa bb' );
$scored->tweak( 'smoothing' => 'lidstone', 'alpha' => 0.5 );
my ( $sbest, $sscores ) = $scored->classify('cc');
ok( abs( $sscores->{'only'} - log( 0.5 / 3 ) ) < 1e-9, 'tweaked alpha is used when classifying' );

# switching to lidstone without a alpha keeps the current alpha
my $keep = Algorithm::Classifier::NaiveBayes->new;
$keep->tweak( 'smoothing' => 'lidstone' );
is( $keep->{'model'}{'alpha'}, 1, 'switching to lidstone without alpha keeps the current alpha' );

# switching back to laplace forces alpha back to 1
$nb->tweak( 'smoothing' => 'laplace' );
is( $nb->{'model'}{'smoothing'}, 'laplace', 'tweak can switch back to laplace' );
is( $nb->{'model'}{'alpha'},     1,         'switching to laplace forces alpha to 1' );

##
## priors
##

$nb->tweak( 'priors' => 'uniform' );
is( $nb->{'model'}{'priors'}, 'uniform', 'tweak changes priors' );
my ( $ubest, $uscores ) = $nb->classify('');
ok( abs( $uscores->{'spam'} - $uscores->{'ham'} ) < 1e-9, 'tweaked priors are used when classifying' );

##
## only defined args are changed
##

my $solo = Algorithm::Classifier::NaiveBayes->new( 'smoothing' => 'lidstone', 'alpha' => 0.3 );
$solo->tweak( 'priors' => 'uniform' );
is( $solo->{'model'}{'smoothing'}, 'lidstone', 'tweaking priors does not touch smoothing' );
is( $solo->{'model'}{'alpha'},     0.3,        'tweaking priors does not touch alpha' );

$solo->tweak( 'smoothing' => undef, 'alpha' => undef, 'priors' => 'trained' );
is( $solo->{'model'}{'priors'},    'trained',  'defined args are still changed alongside undef ones' );
is( $solo->{'model'}{'smoothing'}, 'lidstone', 'undef args are ignored' );
is( $solo->{'model'}{'alpha'},     0.3,        'undef args are ignored' );

eval { $solo->tweak( 'smoothing' => undef ); };
like( $@, qr/No args specified/, 'tweak with only undef values dies' );

##
## a tweaked model still round trips
##

$nb->tweak( 'smoothing' => 'lidstone', 'alpha' => 0.1 );
my $json   = $nb->to_string;
my $loaded = Algorithm::Classifier::NaiveBayes->new;
$loaded->from_string($json);
is_deeply( $loaded->{'model'}, $nb->{'model'}, 'tweaked model survives save and load' );

done_testing;

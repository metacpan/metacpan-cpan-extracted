#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

use Algorithm::Classifier::NaiveBayes;

my $nb = Algorithm::Classifier::NaiveBayes->new;
$nb->train( 'spam', 'buy cheap pills now cheap' );
$nb->train( 'ham',  'meeting at noon tomorrow' );
$nb->train( 'ham',  'lunch meeting tomorrow' );

# untrained and undef handling
my $empty = Algorithm::Classifier::NaiveBayes->new;
is( $empty->explain('anything'), undef, 'untrained explain returns undef' );

eval { $nb->explain(); };
like( $@, qr/No text specified/, 'explain with undef text dies' );

my $explanation = $nb->explain('cheap pills meeting cheap');

# structure
is( ref($explanation), 'HASH', 'explain returns a hash ref' );
foreach my $key ( 'scores', 'probs', 'priors', 'tokens' ) {
	is( ref( $explanation->{$key} ), 'HASH', $key . ' is a hash ref' );
}

# agrees with classify
my ( $class, $scores, $probs ) = $nb->classify('cheap pills meeting cheap');
is( $explanation->{'class'}, $class, 'explain class matches classify' );
is_deeply( $explanation->{'scores'}, $scores, 'explain scores match classify' );
is_deeply( $explanation->{'probs'},  $probs,  'explain probs match classify' );

# token info
is( $explanation->{'tokens'}{'cheap'}{'count'}, 2, 'token count reflects the text' );
is( $explanation->{'tokens'}{'pills'}{'count'}, 1, 'token count reflects the text' );
ok(
	$explanation->{'tokens'}{'cheap'}{'contributions'}{'spam'}
		> $explanation->{'tokens'}{'cheap'}{'contributions'}{'ham'},
	'spammy token contributes more to spam'
);
ok(
	$explanation->{'tokens'}{'meeting'}{'contributions'}{'ham'}
		> $explanation->{'tokens'}{'meeting'}{'contributions'}{'spam'},
	'hammy token contributes more to ham'
);

# unseen tokens still get a smoothed contribution
my $unseen = $nb->explain('zebra');
ok( defined( $unseen->{'tokens'}{'zebra'}{'contributions'}{'spam'} ), 'unseen tokens have a smoothed contribution' );

# the score is the prior plus the sum of count * contribution
foreach my $check_class ( 'spam', 'ham' ) {
	my $rebuilt = $explanation->{'priors'}{$check_class};
	foreach my $token ( keys %{ $explanation->{'tokens'} } ) {
		$rebuilt += $explanation->{'tokens'}{$token}{'contributions'}{$check_class}
			* $explanation->{'tokens'}{$token}{'count'};
	}
	ok(
		abs( $rebuilt - $explanation->{'scores'}{$check_class} ) < 1e-9,
		'prior plus token contributions rebuilds the ' . $check_class . ' score'
	);
} ## end foreach my $check_class ( 'spam', 'ham' )

# priors reflect training frequency
ok( $explanation->{'priors'}{'ham'} > $explanation->{'priors'}{'spam'}, 'the more trained class has the higher prior' );

# uniform priors show up in the explanation
my $uniform = Algorithm::Classifier::NaiveBayes->new( 'priors' => 'uniform' );
$uniform->train( 'spam', 'buy cheap pills' );
$uniform->train( 'ham',  'meeting at noon' );
$uniform->train( 'ham',  'lunch meeting' );
my $uniform_explanation = $uniform->explain('cheap meeting');
ok( abs( $uniform_explanation->{'priors'}{'spam'} - $uniform_explanation->{'priors'}{'ham'} ) < 1e-9,
	'uniform priors are equal in explain' );

done_testing;

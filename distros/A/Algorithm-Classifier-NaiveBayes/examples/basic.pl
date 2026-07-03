#!perl
# A minimal example. Trains a classifier with a few spam and ham
# examples, classifies some new strings, and uses explain to show
# which tokens pushed each one towards its class.
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes;

my $nb = Algorithm::Classifier::NaiveBayes->new;

$nb->train( 'spam', 'buy cheap pills now' );
$nb->train( 'spam', 'cheap watches for sale' );
$nb->train( 'spam', 'you have won a free cruise' );
$nb->train( 'ham',  'meeting at noon tomorrow' );
$nb->train( 'ham',  'lunch with the team' );
$nb->train( 'ham',  'the report is attached' );

my @to_classify = ( 'cheap pills for sale', 'can we move the meeting to after lunch', 'you have won free pills', );

foreach my $text (@to_classify) {
	my $explanation = $nb->explain($text);
	my $class       = $explanation->{'class'};

	print '"' . $text . '" -> ' . $class . ', probability ' . sprintf( '%.3f', $explanation->{'probs'}{$class} ) . "\n";

	# show what each token contributed, sorted by how hard it pushed
	# towards the winning class over the runner up
	my ( $first, $second ) = sort { $explanation->{'scores'}{$b} <=> $explanation->{'scores'}{$a} }
		keys %{ $explanation->{'scores'} };
	my %pull;
	foreach my $token ( keys %{ $explanation->{'tokens'} } ) {
		my $contribs = $explanation->{'tokens'}{$token}{'contributions'};
		$pull{$token} = ( $contribs->{$first} - $contribs->{$second} ) * $explanation->{'tokens'}{$token}{'count'};
	}
	foreach my $token ( sort { $pull{$b} <=> $pull{$a} } keys %pull ) {
		my $towards = $pull{$token} > 0 ? $first : $second;
		print '    ' . $token . ' pushed towards ' . $towards . ' by ' . sprintf( '%.3f', abs( $pull{$token} ) ) . "\n";
	}
} ## end foreach my $text (@to_classify)

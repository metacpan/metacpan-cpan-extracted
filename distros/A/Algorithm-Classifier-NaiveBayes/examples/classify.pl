#!perl
# Classifies text using a model saved by train.pl, printing the best
# match and then the score for every class.
#
#     perl classify.pl model.json 'cheap pills for sale'
#
# Or read the text to classify from stdin...
#
#     cat some_message.txt | perl classify.pl model.json
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes;

my $model_file = shift(@ARGV);
if ( !defined($model_file) ) {
	die( 'Usage: classify.pl <model.json> [text]' . "\n" );
}

my $text;
if (@ARGV) {
	$text = join( ' ', @ARGV );
} else {
	$text = do { local $/; <STDIN> };
}
if ( !defined($text) || $text eq '' ) {
	die( 'Nothing to classify' . "\n" );
}

my $nb = Algorithm::Classifier::NaiveBayes->new;
$nb->load($model_file);

my ( $class, $scores ) = $nb->classify($text);
if ( !defined($class) ) {
	die( 'The model has not been trained yet' . "\n" );
}

print 'Best match: ' . $class . "\n";
foreach my $possible ( sort { $scores->{$b} <=> $scores->{$a} } keys %{$scores} ) {
	print '    ' . $possible . ': ' . $scores->{$possible} . "\n";
}

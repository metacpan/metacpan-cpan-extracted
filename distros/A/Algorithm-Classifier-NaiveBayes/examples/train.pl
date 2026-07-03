#!perl
# Trains a class in a saved model with the specified text, creating
# the model file if it does not exist yet.
#
#     perl train.pl model.json spam 'buy cheap pills now'
#     perl train.pl model.json ham 'meeting at noon tomorrow'
#
# Or read the text to train from stdin...
#
#     cat some_spam.txt | perl train.pl model.json spam
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes;

my $model_file = shift(@ARGV);
my $class      = shift(@ARGV);
if ( !defined($model_file) || !defined($class) ) {
	die( 'Usage: train.pl <model.json> <class> [text]' . "\n" );
}

my $text;
if (@ARGV) {
	$text = join( ' ', @ARGV );
} else {
	$text = do { local $/; <STDIN> };
}
if ( !defined($text) || $text eq '' ) {
	die( 'Nothing to train' . "\n" );
}

my $nb = Algorithm::Classifier::NaiveBayes->new;
if ( -f $model_file ) {
	$nb->load($model_file);
}

$nb->train( $class, $text );
$nb->save($model_file);

print 'Trained "' . $class . '", ' . $nb->{'model'}{'total_docs'} . ' total documents in the model' . "\n";

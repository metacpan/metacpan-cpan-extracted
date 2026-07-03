package Algorithm::Classifier::NaiveBayes::App::Command::classify;

use 5.006;
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes ();
use Algorithm::Classifier::NaiveBayes::App -command;
use JSON::PP ();

sub options {
	return (
		[ 'm=s',  'Model JSON file path/name.', { 'default' => 'nb_model.json', 'completion' => 'files' } ],
		[ 's',    'Also print the log score of every class.' ],
		[ 'p',    'Also print the probability of every class.' ],
		[ 'json', 'Print the class, scores, and probs as JSON instead.' ],
	);
}

sub abstract { 'Classify the specified text' }

sub description {
	return 'Classify the specified text using a saved model.

The text is taken from the remaining args joined by a space, or from
stdin if no args are given. The best matching class is printed.

    nb_tool classify -m model.json cheap pills for sale
    cat some_message.txt | nb_tool classify -m model.json -p
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	}

	return 1;
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $nb = Algorithm::Classifier::NaiveBayes->new;
	$nb->load( $opt->{'m'} );

	my ( $class, $scores, $probs ) = $nb->classify( $self->text_from($args) );
	if ( !defined($class) ) {
		die('The model has not been trained yet');
	}

	if ( $opt->{'json'} ) {
		print JSON::PP->new->canonical->pretty->encode( { 'class' => $class, 'scores' => $scores, 'probs' => $probs } );
		return;
	}

	print $class. "\n";

	if ( $opt->{'s'} ) {
		print "scores:\n";
		foreach my $possible ( sort { $scores->{$b} <=> $scores->{$a} } keys %{$scores} ) {
			print '    ' . $possible . ': ' . $scores->{$possible} . "\n";
		}
	}
	if ( $opt->{'p'} ) {
		print "probs:\n";
		foreach my $possible ( sort { $probs->{$b} <=> $probs->{$a} } keys %{$probs} ) {
			print '    ' . $possible . ': ' . $probs->{$possible} . "\n";
		}
	}
} ## end sub execute

1;

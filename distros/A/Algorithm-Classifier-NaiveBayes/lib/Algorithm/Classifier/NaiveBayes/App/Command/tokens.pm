package Algorithm::Classifier::NaiveBayes::App::Command::tokens;

use 5.006;
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes ();
use Algorithm::Classifier::NaiveBayes::App -command;

sub options {
	return (
		[ 'm=s', 'Model JSON file path/name.', { 'default' => 'nb_model.json', 'completion' => 'files' } ],
		[ 'c',   'Also print the count for each token.' ],
	);
}

sub abstract { 'List the tokens trained for a class' }

sub description {
	return 'List the tokens trained for the specified class, one per line.

    nb_tool tokens -m model.json spam
    nb_tool tokens -m model.json -c spam
';
}

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	}

	if ( !defined( $args->[0] ) ) {
		$self->usage_error('No class specified');
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $nb = Algorithm::Classifier::NaiveBayes->new;
	$nb->load( $opt->{'m'} );

	my $class = $args->[0];
	foreach my $token ( $nb->class_tokens($class) ) {
		if ( $opt->{'c'} ) {
			print $token. ': ' . $nb->{'model'}{'token_counts'}{$class}{$token} . "\n";
		} else {
			print $token. "\n";
		}
	}
} ## end sub execute

1;

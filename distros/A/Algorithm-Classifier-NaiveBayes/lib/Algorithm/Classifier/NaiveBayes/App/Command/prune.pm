package Algorithm::Classifier::NaiveBayes::App::Command::prune;

use 5.006;
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes ();
use Algorithm::Classifier::NaiveBayes::App -command;

sub options {
	return ( [ 'm=s', 'Model JSON file path/name.', { 'default' => 'nb_model.json', 'completion' => 'files' } ], );
}

sub abstract { 'Prune rarely seen tokens from a saved model' }

sub description {
	return 'Prune all tokens trained fewer than the specified number of times.

The count is totaled across all classes. The min count is taken from
the remaining args.

    # remove all tokens only trained once
    nb_tool prune -m model.json 2
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	}

	if ( !defined( $args->[0] ) ) {
		$self->usage_error('No min count specified');
	}
	if ( $args->[0] !~ /\A\d+\z/ || $args->[0] < 1 ) {
		$self->usage_error( 'The min count, "' . $args->[0] . '", is not a whole number greater than 0' );
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $nb = Algorithm::Classifier::NaiveBayes->new;
	$nb->load( $opt->{'m'} );

	my $pruned = $nb->prune( $args->[0] );
	$nb->save( $opt->{'m'} );

	print 'Pruned '
		. $pruned
		. ' tokens, '
		. scalar( keys %{ $nb->{'model'}{'tokens'} } )
		. ' remaining in the vocabulary' . "\n";
} ## end sub execute

1;

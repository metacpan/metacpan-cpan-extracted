package Algorithm::Classifier::NaiveBayes::App::Command::tweak;

use 5.006;
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes ();
use Algorithm::Classifier::NaiveBayes::App -command;

sub options {
	return (
		[ 'm=s',         'Model JSON file path/name.', { 'default' => 'nb_model.json', 'completion' => 'files' } ],
		[ 'smoothing=s', 'Smoothing to use... laplace or lidstone.' ],
		[ 'alpha=f',     'Alpha for lidstone smoothing.' ],
		[ 'priors=s',    'How class priors are computed... trained or uniform.' ],
	);
}

sub abstract { 'Change scoring settings on a saved model' }

sub description {
	return 'Change scoring settings on a saved model.

Only smoothing, alpha, and priors may be changed as they only affect
scoring, not the trained counts. Settings that shape the trained data,
such as ngrams and token-weighting, would make the model inconsistent
with what was trained... for those, create a new model and retrain.

    nb_tool tweak -m model.json --smoothing lidstone --alpha 0.1
    nb_tool tweak -m model.json --priors uniform
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	}

	if ( !defined( $opt->{'smoothing'} ) && !defined( $opt->{'alpha'} ) && !defined( $opt->{'priors'} ) ) {
		$self->usage_error('Nothing to change... at least one of --smoothing, --alpha, or --priors is needed');
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $nb = Algorithm::Classifier::NaiveBayes->new;
	$nb->load( $opt->{'m'} );

	$nb->tweak(
		'smoothing' => $opt->{'smoothing'},
		'alpha'     => $opt->{'alpha'},
		'priors'    => $opt->{'priors'},
	);
	$nb->save( $opt->{'m'} );

	foreach my $setting ( 'smoothing', 'alpha', 'priors' ) {
		print $setting . ': ' . $nb->{'model'}{$setting} . "\n";
	}
} ## end sub execute

1;

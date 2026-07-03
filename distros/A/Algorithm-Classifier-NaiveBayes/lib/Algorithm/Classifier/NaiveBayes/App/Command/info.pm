package Algorithm::Classifier::NaiveBayes::App::Command::info;

use 5.006;
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes ();
use Algorithm::Classifier::NaiveBayes::App -command;

sub options {
	return ( [ 'm=s', 'Model JSON file path/name.', { 'default' => 'nb_model.json', 'completion' => 'files' } ], );
}

sub abstract { 'Show settings and stats for a saved model' }

sub description {
	return 'Show the settings, classes, and stats for a saved model.

    nb_tool info -m model.json
';
}

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

	my $model = $nb->{'model'};
	foreach my $setting (
		'format',          'version', 'lc_tokens', 'token_splitter',
		'stop_regex',      'ngrams',  'smoothing', 'alpha',
		'token_weighting', 'priors'
		)
	{
		print $setting . ': ' . ( defined( $model->{$setting} ) ? $model->{$setting} : 'undef' ) . "\n";
	}

	print 'total_docs: ' . $model->{'total_docs'} . "\n";
	print 'vocabulary_size: ' . scalar( keys %{ $model->{'tokens'} } ) . "\n";
	print "classes:\n";
	foreach my $class ( $nb->classes ) {
		print '    '
			. $class
			. ': docs='
			. $model->{'class_counts'}{$class}
			. ' tokens='
			. $model->{'class_totals'}{$class} . "\n";
	}
} ## end sub execute

1;

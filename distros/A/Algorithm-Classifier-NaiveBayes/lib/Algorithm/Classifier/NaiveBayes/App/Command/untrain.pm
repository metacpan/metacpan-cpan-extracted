package Algorithm::Classifier::NaiveBayes::App::Command::untrain;

use 5.006;
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes ();
use Algorithm::Classifier::NaiveBayes::App -command;
use File::Slurp qw(read_file);

sub options {
	return (
		[ 'm=s', 'Model JSON file path/name.', { 'default' => 'nb_model.json', 'completion' => 'files' } ],
		[ 'c=s', 'Class to untrain.' ],
		[ 'f=s', 'File to read the text from.', { 'completion' => 'files' } ],
	);
}

sub abstract { 'Untrain a class on the specified text' }

sub description {
	return 'Untrain a class on the specified text, reversing a previous train.

The text is taken from the file specified via -f, the remaining args
joined by a space, or from stdin.

    nb_tool untrain -m model.json -c spam something that is not spam
    nb_tool untrain -m model.json -c spam -f some_ham.txt
    cat ham | nb_tool untrain -m model.json -c spam
';
} ## end sub description

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !defined( $opt->{'c'} ) ) {
		$self->usage_error('-c has not been specified');
	}

	if ( !-f $opt->{'m'} ) {
		$self->usage_error( '-m, "' . $opt->{'m'} . '", is not a file or does not exist' );
	}

	if ( defined( $opt->{'f'} ) ) {
		if ( @{$args} ) {
			$self->usage_error('-f and text args may not be used together');
		}
		if ( !-f $opt->{'f'} ) {
			$self->usage_error( '-f, "' . $opt->{'f'} . '", is not a file or does not exist' );
		} elsif ( !-r $opt->{'f'} ) {
			$self->usage_error( '-f, "' . $opt->{'f'} . '", is not readable' );
		}
	} ## end if ( defined( $opt->{'f'} ) )

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $nb = Algorithm::Classifier::NaiveBayes->new;
	$nb->load( $opt->{'m'} );

	my $text = defined( $opt->{'f'} ) ? read_file( $opt->{'f'} ) : $self->text_from($args);
	$nb->untrain( $opt->{'c'}, $text );
	$nb->save( $opt->{'m'} );

	print 'Untrained "' . $opt->{'c'} . '", ' . $nb->{'model'}{'total_docs'} . ' total documents in the model' . "\n";
} ## end sub execute

1;

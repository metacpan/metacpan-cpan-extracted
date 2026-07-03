package Algorithm::Classifier::NaiveBayes::App::Command::train;

use 5.006;
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes ();
use Algorithm::Classifier::NaiveBayes::App -command;
use File::Slurp qw(read_file);

sub options {
	return (
		[ 'm=s', 'Model JSON file path/name.', { 'default' => 'nb_model.json', 'completion' => 'files' } ],
		[ 'c=s', 'Class to train.' ],
		[ 'f=s', 'File to read the text from.', { 'completion' => 'files' } ],
		[ 'token-splitter=s',  'New model only. Regex to use for splitting a string into tokens.' ],
		[ 'stop-regex=s',      'New model only. Drop tokens entirely matching this regex.' ],
		[ 'no-lc',             'New model only. Do not lowercase tokens.' ],
		[ 'smoothing=s',       'New model only. Smoothing to use... laplace or lidstone.' ],
		[ 'alpha=f',           'New model only. Alpha for lidstone smoothing.' ],
		[ 'ngrams=i',          'New model only. Max size of n-grams to generate from adjacent tokens.' ],
		[ 'token-weighting=s', 'New model only. How token occurrences are weighted... count or binary.' ],
		[ 'priors=s',          'New model only. How class priors are computed... trained or uniform.' ],
	);
} ## end sub options

sub abstract { 'Train a class on the specified text' }

sub description {
	return 'Train a class on the specified text, creating the model file if needed.

The text is taken from the file specified via -f, the remaining args
joined by a space, or from stdin.

    nb_tool train -m model.json -c spam buy cheap pills now
    nb_tool train -m model.json -c spam -f some_spam.txt
    cat some_spam.txt | nb_tool train -m model.json -c spam

Model settings such as --smoothing may only be specified when the
model file does not exist yet, as they are stored in the model.
';
} ## end sub description

my @new_args = ( 'token_splitter', 'stop_regex', 'smoothing', 'alpha', 'ngrams', 'token_weighting', 'priors' );

sub validate {
	my ( $self, $opt, $args ) = @_;

	if ( !defined( $opt->{'c'} ) ) {
		$self->usage_error('-c has not been specified');
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

	if ( -f $opt->{'m'} ) {
		foreach my $new_arg ( @new_args, 'no_lc' ) {
			if ( defined( $opt->{$new_arg} ) ) {
				my $flag = $new_arg;
				$flag =~ s/_/-/g;
				$self->usage_error( '--' . $flag . ' may only be used when creating a new model file' );
			}
		}
	}

	return 1;
} ## end sub validate

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $nb;
	if ( -f $opt->{'m'} ) {
		$nb = Algorithm::Classifier::NaiveBayes->new;
		$nb->load( $opt->{'m'} );
	} else {
		my %args_for_new;
		foreach my $new_arg (@new_args) {
			if ( defined( $opt->{$new_arg} ) ) {
				$args_for_new{$new_arg} = $opt->{$new_arg};
			}
		}
		if ( $opt->{'no_lc'} ) {
			$args_for_new{'lc_tokens'} = 0;
		}
		$nb = Algorithm::Classifier::NaiveBayes->new(%args_for_new);
	} ## end else [ if ( -f $opt->{'m'} ) ]

	my $text = defined( $opt->{'f'} ) ? read_file( $opt->{'f'} ) : $self->text_from($args);
	$nb->train( $opt->{'c'}, $text );
	$nb->save( $opt->{'m'} );

	print 'Trained "' . $opt->{'c'} . '", ' . $nb->{'model'}{'total_docs'} . ' total documents in the model' . "\n";
} ## end sub execute

1;

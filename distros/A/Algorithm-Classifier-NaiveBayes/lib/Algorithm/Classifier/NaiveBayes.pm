package Algorithm::Classifier::NaiveBayes;

use 5.006;
use strict;
use warnings;
use JSON::PP    ();
use File::Slurp qw(read_file write_file);

=head1 NAME

Algorithm::Classifier::NaiveBayes - A multinomial naive Bayes text classifier with Laplace smoothing.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

# version of the saved model format
our $MODEL_VERSION = 1;

=head1 SYNOPSIS

    use Algorithm::Classifier::NaiveBayes;

    my $nb = Algorithm::Classifier::NaiveBayes->new;

    # train it with examples of each class
    $nb->train( 'spam', 'buy cheap pills now' );
    $nb->train( 'spam', 'cheap watches for sale' );
    $nb->train( 'ham',  'meeting at noon tomorrow' );
    $nb->train( 'ham',  'lunch with the team' );

    # classify some new text
    my $class = $nb->classify('cheap pills for sale');
    # $class is now 'spam'

    # or get the score and probability for every class as well
    my ( $best, $scores, $probs ) = $nb->classify('cheap pills for sale');

    # save the model for later and load it again
    $nb->save('model.json');

    my $loaded = Algorithm::Classifier::NaiveBayes->new;
    $loaded->load('model.json');

=head1 DESCRIPTION

This module implements a multinomial naive Bayes classifier. Strings
are broken into tokens and each class is scored using the log of its
prior probability, based on how often the class was trained, plus the
sum of the log probabilities of each token appearing in that class.
Token probabilities are smoothed so tokens never seen for a class do
not zero out the whole score. By default this is add-one, Laplace,
smoothing, but Lidstone, add-alpha, smoothing with a configurable
alpha may be selected instead. Smaller alphas, such as 0.1 to 0.5,
often perform better on small training sets.

By default token occurrences are weighted by their raw counts, but
binary weighting, counting each unique token once per document, may
be selected instead via token_weighting. Class priors default to how
often each class was trained, but may be set to uniform via priors.

Classes are not predefined. A class exists once something has been
trained for it and stops existing if everything for it is untrained.

The model may be saved to a JSON file or string and loaded back later,
allowing training and classification to happen in different processes.

=head1 METHODS

=head2 new

Initiates the object.

    my $nb = Algorithm::Classifier::NaiveBayes->new(%args);

The following args are supported.

    lc_tokens - Lowercase tokens when tokenizing.
        Default: 1

    token_splitter - Regex to use for splitting a string into tokens.
        Default: \s+

    stop_regex - If defined, tokens matching this regex are dropped.
        Matched anchored, so it must match the entire token.
        Default: undef

    smoothing - The smoothing to use for token probabilities. Either
        "laplace", add-one, or "lidstone", add-alpha.
        Default: laplace

    alpha - The alpha to use for lidstone smoothing. Must be a number
        greater than 0. May only be specified when smoothing is set to
        lidstone. Laplace smoothing is lidstone with a alpha of 1.
        Default: 0.5

    ngrams - Max size of n-grams to generate from adjacent tokens when
        tokenizing. 1 means single tokens only. 2 means also generate
        each adjacent pair of tokens joined by a space. 3 also adds
        triplets and so on.
        Default: 1

    token_weighting - How token occurrences are weighted. "count" uses
        raw counts, so a token appearing three times in a document
        counts three times. "binary" counts each unique token once per
        document, both when training and classifying, which often works
        better for short texts. Also known as binarized multinomial
        naive Bayes.
        Default: count

    priors - How class priors are computed when classifying. "trained"
        uses how often each class was trained, so classes with more
        documents are favored. "uniform" gives every class a equal
        prior, useful when the training set is unbalanced in a way real
        usage will not be.
        Default: trained

token_splitter and stop_regex may be either a string or a qr// Regexp.

Will die if passed a unknown arg or if token_splitter or stop_regex
is a empty string, a ref other than a qr// Regexp, or does not compile
as a regex.

Some examples...

    # split on commas instead of whitespace
    my $nb = Algorithm::Classifier::NaiveBayes->new( 'token_splitter' => ',' );

    # keep the case of tokens
    my $nb = Algorithm::Classifier::NaiveBayes->new( 'lc_tokens' => 0 );

    # drop some common stop words
    my $nb = Algorithm::Classifier::NaiveBayes->new( 'stop_regex' => qr/a|an|and|the|of|to/ );

    # use lidstone smoothing with a alpha of 0.1
    my $nb = Algorithm::Classifier::NaiveBayes->new( 'smoothing' => 'lidstone', 'alpha' => 0.1 );

    # also generate bigrams, so phrases like "free cruise" become tokens
    my $nb = Algorithm::Classifier::NaiveBayes->new( 'ngrams' => 2 );

    # count each unique token once per document
    my $nb = Algorithm::Classifier::NaiveBayes->new( 'token_weighting' => 'binary' );

    # give every class a equal prior regardless of training balance
    my $nb = Algorithm::Classifier::NaiveBayes->new( 'priors' => 'uniform' );

=cut

sub new {
	my ( $pkg, %args ) = @_;

	my %known_args = (
		'lc_tokens'       => 1,
		'token_splitter'  => 1,
		'stop_regex'      => 1,
		'smoothing'       => 1,
		'alpha'           => 1,
		'ngrams'          => 1,
		'token_weighting' => 1,
		'priors'          => 1,
	);
	foreach my $arg ( keys %args ) {
		if ( !defined( $known_args{$arg} ) ) {
			die( '"' . $arg . '" is not a known arg' );
		}
	}

	if ( defined( $args{'lc_tokens'} ) && ref( $args{'lc_tokens'} ) ne '' ) {
		die( 'lc_tokens must be a boolean and not a ref of type "' . ref( $args{'lc_tokens'} ) . '"' );
	}

	foreach my $regex_arg ( 'token_splitter', 'stop_regex' ) {
		if ( defined( $args{$regex_arg} ) ) {
			my $ref = ref( $args{$regex_arg} );
			if ( $ref ne '' && $ref ne 'Regexp' ) {
				die( $regex_arg . ' must be a string or qr// Regexp and not a ref of type "' . $ref . '"' );
			}
			if ( $args{$regex_arg} eq '' ) {
				die( $regex_arg . ' may not be a empty string' );
			}
			my $compiled = eval { qr/$args{$regex_arg}/ };
			if ( !defined($compiled) ) {
				die( $regex_arg . ', "' . $args{$regex_arg} . '", does not compile as a regex... ' . $@ );
			}
		} ## end if ( defined( $args{$regex_arg} ) )
	} ## end foreach my $regex_arg ( 'token_splitter', 'stop_regex')

	my $smoothing = defined( $args{'smoothing'} ) ? $args{'smoothing'} : 'laplace';
	if ( $smoothing ne 'laplace' && $smoothing ne 'lidstone' ) {
		die( 'smoothing must be either "laplace" or "lidstone" and not "' . $smoothing . '"' );
	}
	my $alpha;
	if ( defined( $args{'alpha'} ) ) {
		if ( $smoothing eq 'laplace' ) {
			die('alpha may only be specified when smoothing is set to lidstone');
		}
		if ( ref( $args{'alpha'} ) ne '' || $args{'alpha'} !~ /\A\d*\.?\d+\z/ || $args{'alpha'} <= 0 ) {
			die('alpha must be a number greater than 0');
		}
		$alpha = $args{'alpha'};
	} else {
		$alpha = $smoothing eq 'lidstone' ? 0.5 : 1;
	}

	my $ngrams = defined( $args{'ngrams'} ) ? $args{'ngrams'} : 1;
	if ( ref($ngrams) ne '' || $ngrams !~ /\A\d+\z/ || $ngrams < 1 ) {
		die('ngrams must be a whole number greater than 0');
	}

	my $token_weighting = defined( $args{'token_weighting'} ) ? $args{'token_weighting'} : 'count';
	if ( $token_weighting ne 'count' && $token_weighting ne 'binary' ) {
		die( 'token_weighting must be either "count" or "binary" and not "' . $token_weighting . '"' );
	}

	my $priors = defined( $args{'priors'} ) ? $args{'priors'} : 'trained';
	if ( $priors ne 'trained' && $priors ne 'uniform' ) {
		die( 'priors must be either "trained" or "uniform" and not "' . $priors . '"' );
	}

	my $self = {
		'model' => {
			'format'          => __PACKAGE__,
			'version'         => $MODEL_VERSION,
			'smoothing'       => $smoothing,
			'alpha'           => $alpha,
			'ngrams'          => $ngrams,
			'token_weighting' => $token_weighting,
			'priors'          => $priors,
			'class_counts'    => {},
			'token_counts'    => {},
			'class_totals'    => {},
			'tokens'          => {},
			'total_docs'      => 0,
			'lc_tokens'       => defined( $args{'lc_tokens'} )      ? $args{'lc_tokens'}      : 1,
			'token_splitter'  => defined( $args{'token_splitter'} ) ? $args{'token_splitter'} : '\s+',
			'stop_regex'      => $args{'stop_regex'},
		},
	};
	bless $self, $pkg;

	return $self;
} ## end sub new

=head2 tokenize

Tokenizes the specified string. This is used internally by train,
untrain, and classify, but may also be called directly to see how a
string will be broken up.

    my @tokens = $nb->tokenize($string);

The string is split via the token_splitter regex. Empty tokens are
dropped. If lc_tokens is true, tokens are lowercased. If stop_regex is
defined, tokens entirely matching it are dropped.

If ngrams is greater than 1, n-grams up to that size are generated
from adjacent tokens and appended, joined by a space. This happens
after lowercasing and stop word removal, so stop words do not appear
inside n-grams.

    my $nb = Algorithm::Classifier::NaiveBayes->new( 'ngrams' => 2 );
    my @tokens = $nb->tokenize('Free Cruise Inside');
    # ( 'free', 'cruise', 'inside', 'free cruise', 'cruise inside' )

Will die if the string is undef. As train, untrain, and classify all
use this, passing undef text to any of those will also die.

    my $nb = Algorithm::Classifier::NaiveBayes->new;
    my @tokens = $nb->tokenize('Buy Cheap  Pills');
    # ( 'buy', 'cheap', 'pills' )

=cut

sub tokenize {
	my ( $self, $text ) = @_;

	if ( !defined($text) ) {
		die('No text specified');
	}

	my $split_regex = $self->{'model'}{'token_splitter'};
	my @tokens      = split( /$split_regex/, $text );
	my @final_tokens;
	foreach my $token (@tokens) {
		if ( $token eq '' ) {
			next;
		}
		if ( $self->{'model'}{'lc_tokens'} ) {
			$token = lc($token);
		}
		my $add_token = 1;
		if ( defined( $self->{'model'}{'stop_regex'} ) ) {
			my $stop_regex = $self->{'model'}{'stop_regex'};
			if ( $token =~ /\A(?:$stop_regex)\z/ ) {
				$add_token = 0;
			}
		}
		if ($add_token) {
			push( @final_tokens, $token );
		}
	} ## end foreach my $token (@tokens)

	# generate n-grams from adjacent tokens if enabled
	if ( defined( $self->{'model'}{'ngrams'} ) && $self->{'model'}{'ngrams'} > 1 ) {
		my @grams;
		for my $n ( 2 .. $self->{'model'}{'ngrams'} ) {
			for my $i ( 0 .. $#final_tokens - $n + 1 ) {
				push( @grams, join( ' ', @final_tokens[ $i .. ( $i + $n - 1 ) ] ) );
			}
		}
		push( @final_tokens, @grams );
	}

	return @final_tokens;
} ## end sub tokenize

=head2 train

Train a specific class on the specified string.

    $nb->train($class, $string);

Will die if the class or string is undef.

The class does not need to exist prior to this being called. Training
a new class name brings that class into existence.

    $nb->train( 'spam', 'buy cheap pills now' );
    $nb->train( 'ham',  'meeting at noon tomorrow' );

=cut

sub train {
	my ( $self, $class, $text ) = @_;

	if ( !defined($class) ) {
		die('No class specified');
	} elsif ( !defined($text) ) {
		die('No text specified');
	}

	$self->{'model'}{'class_counts'}{$class}++;
	$self->{'model'}{'total_docs'}++;
	if ( !defined( $self->{'model'}{'token_counts'}{$class} ) ) {
		$self->{'model'}{'token_counts'}{$class} = {};
	}
	if ( !defined( $self->{'model'}{'class_totals'}{$class} ) ) {
		$self->{'model'}{'class_totals'}{$class} = 0;
	}
	for my $word ( $self->_weighted_tokens( $self->tokenize($text) ) ) {
		$self->{'model'}{'token_counts'}{$class}{$word}++;
		$self->{'model'}{'class_totals'}{$class}++;
		$self->{'model'}{'tokens'}{$word} = 1;
	}
} ## end sub train

# returns the log prior probability for a class per the priors setting
sub _log_prior {
	my ( $self, $class ) = @_;

	if ( defined( $self->{'model'}{'priors'} ) && $self->{'model'}{'priors'} eq 'uniform' ) {
		my $num_classes = scalar keys %{ $self->{'model'}{'class_counts'} };
		return log( 1 / $num_classes );
	}

	return log( $self->{'model'}{'class_counts'}{$class} / $self->{'model'}{'total_docs'} );
} ## end sub _log_prior

# applies the token_weighting setting to a list of tokens... for binary
# weighting each unique token is only counted once
sub _weighted_tokens {
	my ( $self, @tokens ) = @_;

	if ( defined( $self->{'model'}{'token_weighting'} ) && $self->{'model'}{'token_weighting'} eq 'binary' ) {
		my %seen;
		@tokens = grep { !$seen{$_}++ } @tokens;
	}

	return @tokens;
} ## end sub _weighted_tokens

=head2 untrain

Untrain a specific class on the specified string, reversing a previous
call to train with the same class and string.

    $nb->untrain($class, $string);

Will die if the class or string is undef.

If the class in question has not been trained, this is a noop. Token
counts will not be decremented below zero and classes with no remaining
trained documents are removed from the model.

    # trained into the wrong class, so move it
    $nb->untrain( 'ham',  'buy cheap pills now' );
    $nb->train(   'spam', 'buy cheap pills now' );

It is worth noting it can't be verified the string in question was
actually previously trained for that class. Untraining a string that
differs from what was trained will still decrement the document count
for the class, along with whatever tokens overlap.

=cut

sub untrain {
	my ( $self, $class, $text ) = @_;

	if ( !defined($class) ) {
		die('No class specified');
	} elsif ( !defined($text) ) {
		die('No text specified');
	}

	if ( !defined( $self->{'model'}{'class_counts'}{$class} )
		|| $self->{'model'}{'class_counts'}{$class} < 1 )
	{
		return;
	}

	$self->{'model'}{'class_counts'}{$class}--;
	$self->{'model'}{'total_docs'}--;

	for my $word ( $self->_weighted_tokens( $self->tokenize($text) ) ) {
		if ( defined( $self->{'model'}{'token_counts'}{$class}{$word} ) ) {
			$self->{'model'}{'token_counts'}{$class}{$word}--;
			$self->{'model'}{'class_totals'}{$class}--;
			if ( $self->{'model'}{'token_counts'}{$class}{$word} < 1 ) {
				delete( $self->{'model'}{'token_counts'}{$class}{$word} );
			}
		}
	}

	if ( $self->{'model'}{'class_counts'}{$class} < 1 ) {
		delete( $self->{'model'}{'class_counts'}{$class} );
		delete( $self->{'model'}{'token_counts'}{$class} );
		delete( $self->{'model'}{'class_totals'}{$class} );
	}

	# rebuild the vocabulary as some tokens may no longer be in any class
	$self->{'model'}{'tokens'} = {};
	foreach my $rebuild_class ( keys %{ $self->{'model'}{'token_counts'} } ) {
		foreach my $word ( keys %{ $self->{'model'}{'token_counts'}{$rebuild_class} } ) {
			$self->{'model'}{'tokens'}{$word} = 1;
		}
	}
} ## end sub untrain

=head2 prune

Removes all tokens trained fewer than the specified number of times,
totaled across all classes.

    my $pruned = $nb->prune($min_count);

Real world training data tends to accumulate a long tail of tokens
only seen once or twice. Those add noise and bloat the saved model,
so pruning them can be useful after a large amount of training.

    # remove all tokens only trained once
    my $pruned = $nb->prune(2);

Returns the number of tokens removed. Removed tokens are dropped from
the vocabulary and the per class token totals are decremented, but
document counts are untouched, so class priors are unchanged.

Will die if min count is undef or not a whole number greater than 0.
A min count of 1 is a noop as every trained token has a count of at
least 1.

=cut

sub prune {
	my ( $self, $min_count ) = @_;

	if ( !defined($min_count) ) {
		die('No min count specified');
	}
	if ( ref($min_count) ne '' || $min_count !~ /\A\d+\z/ || $min_count < 1 ) {
		die('min count must be a whole number greater than 0');
	}

	# total up each token across all classes
	my %totals;
	foreach my $class ( keys %{ $self->{'model'}{'token_counts'} } ) {
		foreach my $token ( keys %{ $self->{'model'}{'token_counts'}{$class} } ) {
			$totals{$token} += $self->{'model'}{'token_counts'}{$class}{$token};
		}
	}

	my $pruned = 0;
	foreach my $token ( keys %totals ) {
		if ( $totals{$token} < $min_count ) {
			$pruned++;
			foreach my $class ( keys %{ $self->{'model'}{'token_counts'} } ) {
				if ( defined( $self->{'model'}{'token_counts'}{$class}{$token} ) ) {
					$self->{'model'}{'class_totals'}{$class} -= $self->{'model'}{'token_counts'}{$class}{$token};
					delete( $self->{'model'}{'token_counts'}{$class}{$token} );
				}
			}
			delete( $self->{'model'}{'tokens'}{$token} );
		} ## end if ( $totals{$token} < $min_count )
	} ## end foreach my $token ( keys %totals )

	return $pruned;
} ## end sub prune

=head2 classes

Returns a sorted list of all currently trained classes.

    my @classes = $nb->classes;

If nothing has been trained yet, an empty list is returned.

=cut

sub classes {
	my ($self) = @_;

	return sort( keys( %{ $self->{'model'}{'class_counts'} } ) );
}

=head2 class_tokens

Returns a sorted list of all tokens trained for the specified class.

    my @tokens = $nb->class_tokens($class);

Will die if no class is specified or if the class in question does not
exist.

    foreach my $class ( $nb->classes ) {
        print $class . ': ' . join( ', ', $nb->class_tokens($class) ) . "\n";
    }

=cut

sub class_tokens {
	my ( $self, $class ) = @_;

	if ( !defined($class) ) {
		die('No class specified');
	} elsif ( !defined( $self->{'model'}{'token_counts'}{$class} ) ) {
		die( 'The class "' . $class . '" does not exist' );
	}

	return sort( keys( %{ $self->{'model'}{'token_counts'}{$class} } ) );
} ## end sub class_tokens

=head2 classify

Classify the text in question.

    my $class = $nb->classify($text);

In scalar context, returns the name of the class the text most likely
belongs to. In list context, also returns a hash ref of the score for
every class as well as a hash ref of the probability of every class.

    my ( $class, $scores, $probs ) = $nb->classify($text);
    foreach my $possible ( sort { $scores->{$b} <=> $scores->{$a} } keys %{$scores} ) {
        print $possible . ': ' . $scores->{$possible} . ', ' . $probs->{$possible} . "\n";
    }

The scores are log probabilities, so they are negative numbers with
the one closest to zero being the most likely.

The probabilities are the scores normalized to sum to 1, so they may
be used for things like requiring a minimum confidence.

    my ( $class, $scores, $probs ) = $nb->classify($text);
    if ( $probs->{$class} < 0.8 ) {
        $class = 'unsure';
    }

It is worth noting naive Bayes probabilities tend to be overconfident
thanks to the assumption tokens are independent of each other, with
longer texts commonly producing probabilities very close to 1 or 0.
They are good for ranking and thresholding, but should not be taken
as calibrated probabilities.

If nothing has been trained yet, undef is returned in scalar context
and ( undef, {}, {} ) in list context.

Ties are broken by sorting the tied class names, making the result
deterministic.

=cut

sub classify {
	my ( $self, $text ) = @_;

	if ( $self->{'model'}{'total_docs'} < 1 ) {
		return wantarray ? ( undef, {}, {} ) : undef;
	}

	my @tokens     = $self->_weighted_tokens( $self->tokenize($text) );
	my $token_size = scalar keys %{ $self->{'model'}{'tokens'} };
	my $alpha      = defined( $self->{'model'}{'alpha'} ) ? $self->{'model'}{'alpha'} : 1;

	my %scores;
	for my $class ( keys %{ $self->{'model'}{'class_counts'} } ) {
		my $log_prob = $self->_log_prior($class);
		my $total    = $self->{'model'}{'class_totals'}{$class} || 0;

		if ( ( $total + ( $alpha * $token_size ) ) > 0 ) {
			for my $token (@tokens) {
				my $count = $self->{'model'}{'token_counts'}{$class}{$token} || 0;
				$log_prob += log( ( $count + $alpha ) / ( $total + ( $alpha * $token_size ) ) );
			}
		}
		$scores{$class} = $log_prob;
	} ## end for my $class ( keys %{ $self->{'model'}{'class_counts'...}})

	my ($best) = sort { $scores{$b} <=> $scores{$a} || $a cmp $b } keys %scores;

	if ( !wantarray ) {
		return $best;
	}

	# normalize the log scores into probabilities, shifting by the max
	# so exp does not underflow for large negative log scores
	my $max = $scores{$best};
	my %probs;
	my $prob_sum = 0;
	for my $class ( keys %scores ) {
		$probs{$class} = exp( $scores{$class} - $max );
		$prob_sum += $probs{$class};
	}
	for my $class ( keys %probs ) {
		$probs{$class} = $probs{$class} / $prob_sum;
	}

	return ( $best, \%scores, \%probs );
} ## end sub classify

=head2 explain

Classifies the text in question like classify, but returns a hash ref
breaking down how the result was arrived at.

    my $explanation = $nb->explain($text);

The returned hash ref is as below.

    class - The best matching class, as classify would return.

    scores - Hash ref of the log score of every class, as classify
        would return.

    probs - Hash ref of the probability of every class, as classify
        would return.

    priors - Hash ref of the log prior probability of every class,
        the part of the score that comes from how often the class was
        trained rather than from the tokens.

    tokens - Hash ref of every token in the tokenized text. Each value
        is a hash ref with "count", how many times the token appeared
        in the text, and "contributions", a hash ref of the log
        probability that token added to each class per appearance.

For any class, the score is the prior plus count * contribution summed
over every token. A token pushes towards the class it has the highest,
closest to zero, contribution for. So finding the tokens most
responsible for a classification can be done like below.

    my $explanation = $nb->explain($text);
    my ( $first, $second ) =
        sort { $explanation->{'scores'}{$b} <=> $explanation->{'scores'}{$a} }
        keys %{ $explanation->{'scores'} };
    foreach my $token ( keys %{ $explanation->{'tokens'} } ) {
        my $contribs = $explanation->{'tokens'}{$token}{'contributions'};
        my $pull = ( $contribs->{$first} - $contribs->{$second} )
            * $explanation->{'tokens'}{$token}{'count'};
        print $token . ' pushed towards ' . $first . ' by ' . $pull . "\n";
    }

Will die if the text is undef. If nothing has been trained yet, undef
is returned.

=cut

sub explain {
	my ( $self, $text ) = @_;

	if ( !defined($text) ) {
		die('No text specified');
	}

	if ( $self->{'model'}{'total_docs'} < 1 ) {
		return undef;
	}

	my @tokens     = $self->_weighted_tokens( $self->tokenize($text) );
	my $token_size = scalar keys %{ $self->{'model'}{'tokens'} };
	my $alpha      = defined( $self->{'model'}{'alpha'} ) ? $self->{'model'}{'alpha'} : 1;

	my %text_counts;
	foreach my $token (@tokens) {
		$text_counts{$token}++;
	}

	my %priors;
	my %scores;
	my %token_info;
	for my $class ( keys %{ $self->{'model'}{'class_counts'} } ) {
		$priors{$class} = $self->_log_prior($class);
		my $log_prob = $priors{$class};
		my $total    = $self->{'model'}{'class_totals'}{$class} || 0;
		my $denom    = $total + ( $alpha * $token_size );

		if ( $denom > 0 ) {
			foreach my $token ( keys %text_counts ) {
				my $count        = $self->{'model'}{'token_counts'}{$class}{$token} || 0;
				my $contribution = log( ( $count + $alpha ) / $denom );
				$token_info{$token}{'count'} = $text_counts{$token};
				$token_info{$token}{'contributions'}{$class} = $contribution;
				$log_prob += $contribution * $text_counts{$token};
			}
		}
		$scores{$class} = $log_prob;
	} ## end for my $class ( keys %{ $self->{'model'}{'class_counts'...}})

	my ($best) = sort { $scores{$b} <=> $scores{$a} || $a cmp $b } keys %scores;

	my $max = $scores{$best};
	my %probs;
	my $prob_sum = 0;
	for my $class ( keys %scores ) {
		$probs{$class} = exp( $scores{$class} - $max );
		$prob_sum += $probs{$class};
	}
	for my $class ( keys %probs ) {
		$probs{$class} = $probs{$class} / $prob_sum;
	}

	return {
		'class'  => $best,
		'scores' => \%scores,
		'probs'  => \%probs,
		'priors' => \%priors,
		'tokens' => \%token_info,
	};
} ## end sub explain

=head2 tweak

Changes scoring settings on a existing model. Takes the args below,
all optional, but at least one must be specified.

    smoothing - The smoothing to use... laplace or lidstone.

    alpha - The alpha to use for lidstone smoothing. Must be a number
        greater than 0. May only be specified when the resulting
        smoothing is lidstone.

    priors - How class priors are computed... trained or uniform.

    # switch to lidstone smoothing with a alpha of 0.1
    $nb->tweak( 'smoothing' => 'lidstone', 'alpha' => 0.1 );

    # switch to uniform priors
    $nb->tweak( 'priors' => 'uniform' );

These are safe to change after training as they only affect scoring,
not the trained counts. Settings that shape the trained data, such as
ngrams, token_weighting, and the tokenizer settings, may not be
changed here as that would make the model inconsistent with what was
trained... for those, create a new object and retrain.

Only args specified with a defined value are changed. Args passed
with a undef value are ignored, so it is safe to pass through
possibly unset values.

Switching smoothing to laplace sets alpha to 1, as laplace is add-one.
Switching to lidstone without specifying alpha keeps the current
alpha.

Will die if passed a unknown arg, no args with defined values, or a
insane value. If it dies, the model is left unchanged.

=cut

sub tweak {
	my ( $self, %args ) = @_;

	my %known_args = ( 'smoothing' => 1, 'alpha' => 1, 'priors' => 1 );
	foreach my $arg ( keys %args ) {
		if ( !defined( $known_args{$arg} ) ) {
			die( '"' . $arg . '" is not a known arg' );
		}
	}
	if ( !grep { defined( $args{$_} ) } keys %args ) {
		die('No args specified');
	}

	# validate against what the settings would become
	my $smoothing = defined( $args{'smoothing'} ) ? $args{'smoothing'} : $self->{'model'}{'smoothing'};
	if ( !defined($smoothing) ) {
		$smoothing = 'laplace';
	}
	if ( $smoothing ne 'laplace' && $smoothing ne 'lidstone' ) {
		die( 'smoothing must be either "laplace" or "lidstone" and not "' . $smoothing . '"' );
	}

	if ( defined( $args{'alpha'} ) ) {
		if ( $smoothing eq 'laplace' ) {
			die('alpha may only be specified when the resulting smoothing is lidstone');
		}
		if ( ref( $args{'alpha'} ) ne '' || $args{'alpha'} !~ /\A\d*\.?\d+\z/ || $args{'alpha'} <= 0 ) {
			die('alpha must be a number greater than 0');
		}
	}

	if ( defined( $args{'priors'} ) && $args{'priors'} ne 'trained' && $args{'priors'} ne 'uniform' ) {
		die( 'priors must be either "trained" or "uniform" and not "' . $args{'priors'} . '"' );
	}

	# only change what was specified with a defined value
	if ( defined( $args{'smoothing'} ) ) {
		$self->{'model'}{'smoothing'} = $args{'smoothing'};
		if ( $args{'smoothing'} eq 'laplace' ) {
			# laplace is add-one, so alpha is always 1
			$self->{'model'}{'alpha'} = 1;
		}
	}
	if ( defined( $args{'alpha'} ) ) {
		$self->{'model'}{'alpha'} = $args{'alpha'};
	}
	if ( defined( $args{'priors'} ) ) {
		$self->{'model'}{'priors'} = $args{'priors'};
	}
} ## end sub tweak

=head2 to_string

Returns the model as a JSON string. See the section MODEL FORMAT for
what the JSON looks like.

    my $json = $nb->to_string;

The JSON is generated with canonical set, so the keys are sorted,
meaning two calls against the same model will always produce identical
output, making it diffable.

If token_splitter or stop_regex was set to a qr// Regexp, it is
stringified, so the result is always JSON safe.

=cut

sub to_string {
	my ($self) = @_;

	# qr// Regexps can't be JSON encoded, so stringify them
	my %model = %{ $self->{'model'} };
	foreach my $regex_item ( 'token_splitter', 'stop_regex' ) {
		if ( ref( $model{$regex_item} ) eq 'Regexp' ) {
			$model{$regex_item} = '' . $model{$regex_item};
		}
	}

	return JSON::PP->new->encode( \%model );
} ## end sub to_string

=head2 from_string

Loads the model from the specified JSON string, replacing the current
model, including any settings passed to new for the object it is
being called on.

    $nb->from_string($json);

Will die on failure to parse the string as JSON, if "format" in the
JSON is not the name of this module, if "version" is newer than the
supported model format version, or if the parsed JSON does not look
like a saved model.

If it dies, the current model is left unchanged.

=cut

sub from_string {
	my ( $self, $raw ) = @_;

	if ( !defined($raw) ) {
		die('No string specified');
	}

	my $model = eval { JSON::PP->new->decode($raw) };
	if ( !defined($model) ) {
		die( 'Failed to parse the string as JSON... ' . $@ );
	}

	if ( ref($model) ne 'HASH' ) {
		die('The string did not parse to a hash');
	}
	if ( !defined( $model->{'format'} ) || $model->{'format'} ne __PACKAGE__ ) {
		die( '"format" is not "' . __PACKAGE__ . '"' );
	}
	if ( !defined( $model->{'version'} ) || $model->{'version'} !~ /^\d+$/ ) {
		die('"version" is not a int');
	}
	if ( $model->{'version'} > $MODEL_VERSION ) {
		die(      '"version" is '
				. $model->{'version'}
				. ', which is newer than the highest supported model version of '
				. $MODEL_VERSION );
	}
	foreach my $hash_item ( 'class_counts', 'token_counts', 'class_totals', 'tokens' ) {
		if ( ref( $model->{$hash_item} ) ne 'HASH' ) {
			die( '"' . $hash_item . '" is not a hash' );
		}
	}
	if ( !defined( $model->{'total_docs'} ) || $model->{'total_docs'} !~ /\A\d+\z/ ) {
		die('"total_docs" is not a whole number');
	}
	if ( !defined( $model->{'token_splitter'} ) || $model->{'token_splitter'} eq '' ) {
		die('"token_splitter" is undef or a empty string');
	}
	foreach my $regex_item ( 'token_splitter', 'stop_regex' ) {
		if ( defined( $model->{$regex_item} ) && !defined( eval { qr/$model->{$regex_item}/ } ) ) {
			die( '"' . $regex_item . '" does not compile as a regex... ' . $@ );
		}
	}

	# default the optional tunables if missing
	if ( !defined( $model->{'smoothing'} ) ) {
		$model->{'smoothing'} = 'laplace';
	}
	if ( $model->{'smoothing'} ne 'laplace' && $model->{'smoothing'} ne 'lidstone' ) {
		die('"smoothing" is not "laplace" or "lidstone"');
	}
	if ( !defined( $model->{'alpha'} ) ) {
		$model->{'alpha'} = $model->{'smoothing'} eq 'lidstone' ? 0.5 : 1;
	}
	if ( ref( $model->{'alpha'} ) ne '' || $model->{'alpha'} !~ /\A\d*\.?\d+\z/ || $model->{'alpha'} <= 0 ) {
		die('"alpha" is not a number greater than 0');
	}
	if ( $model->{'smoothing'} eq 'laplace' && $model->{'alpha'} != 1 ) {
		die('"alpha" must be 1 when smoothing is "laplace"');
	}

	if ( !defined( $model->{'ngrams'} ) ) {
		$model->{'ngrams'} = 1;
	}
	if ( ref( $model->{'ngrams'} ) ne '' || $model->{'ngrams'} !~ /\A\d+\z/ || $model->{'ngrams'} < 1 ) {
		die('"ngrams" is not a whole number greater than 0');
	}

	if ( !defined( $model->{'token_weighting'} ) ) {
		$model->{'token_weighting'} = 'count';
	}
	if ( $model->{'token_weighting'} ne 'count' && $model->{'token_weighting'} ne 'binary' ) {
		die('"token_weighting" is not "count" or "binary"');
	}

	if ( !defined( $model->{'priors'} ) ) {
		$model->{'priors'} = 'trained';
	}
	if ( $model->{'priors'} ne 'trained' && $model->{'priors'} ne 'uniform' ) {
		die('"priors" is not "trained" or "uniform"');
	}

	$self->{'model'} = $model;
} ## end sub from_string

=head2 save

Saves the model to the specified file as JSON via to_string. The write
is done atomically, written to a temporary file and then renamed into
place, so the file will never contain a partially written model.

    $nb->save('model.json');

Will die if no file is specified or on failure to write the file.

=cut

sub save {
	my ( $self, $file ) = @_;

	if ( !defined($file) ) {
		die('No file specified');
	}

	my $raw = $self->to_string;

	eval { write_file( $file, { 'atomic' => 1, 'err_mode' => 'croak' }, $raw ); };
	if ($@) {
		die( 'Failed to write "' . $file . '"... ' . $@ );
	}
} ## end sub save

=head2 load

Loads the model from the specified file via from_string, replacing the
current model.

    $nb->load('model.json');

Will die if no file is specified, on failure to read the file, failure
to parse it as JSON, or if the parsed JSON does not look like a saved
model.

If it dies, the current model is left unchanged.

=cut

sub load {
	my ( $self, $file ) = @_;

	if ( !defined($file) ) {
		die('No file specified');
	}

	my $raw = eval { read_file( $file, { 'err_mode' => 'croak' } ); };
	if ( !defined($raw) ) {
		die( 'Failed to read "' . $file . '"... ' . $@ );
	}

	eval { $self->from_string($raw); };
	if ($@) {
		die( 'Failed to load the model from "' . $file . '"... ' . $@ );
	}
} ## end sub load

=head1 MODEL FORMAT

The model as produced by to_string and save is a JSON hash like the
below.

    {
       "format" : "Algorithm::Classifier::NaiveBayes",
       "version" : 1,
       "smoothing" : "laplace",
       "alpha" : 1,
       "ngrams" : 1,
       "token_weighting" : "count",
       "priors" : "trained",
       "class_counts" : {
          "ham" : 1,
          "spam" : 1
       },
       "class_totals" : {
          "ham" : 4,
          "spam" : 4
       },
       "token_counts" : {
          "ham" : {
             "at" : 1,
             "meeting" : 1,
             "noon" : 1,
             "tomorrow" : 1
          },
          "spam" : {
             "buy" : 1,
             "cheap" : 1,
             "now" : 1,
             "pills" : 1
          }
       },
       "tokens" : {
          "at" : 1,
          "buy" : 1,
          "cheap" : 1,
          "meeting" : 1,
          "noon" : 1,
          "now" : 1,
          "pills" : 1,
          "tomorrow" : 1
       },
       "total_docs" : 2,
       "lc_tokens" : 1,
       "token_splitter" : "\\s+",
       "stop_regex" : null
    }

The keys are as below.

    format - The name of this module. Used by from_string to make sure
        the JSON is actually a saved model.

    version - The version of the model format. Currently 1. from_string
        will refuse to load a model with a version newer than it
        understands. Models missing any of the optional tunables,
        smoothing, alpha, ngrams, token_weighting, or priors, are
        loaded with those keys defaulted.

    class_counts - Per class count of how many documents have been
        trained.

    class_totals - Per class count of how many tokens have been
        trained.

    token_counts - Per class hash of token to how many times that
        token has been trained.

    tokens - A hash of every token trained across all classes. The
        size of this is the vocabulary size used for smoothing.

    total_docs - Total number of documents trained across all classes.

    lc_tokens, token_splitter, stop_regex, ngrams - The tokenizer
        settings as documented under new.

    smoothing, alpha - The smoothing settings as documented under new.

    token_weighting - The token weighting setting as documented under
        new.

    priors - The class prior setting as documented under new.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-algorithm-classifier-naivebayes at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Classifier-NaiveBayes>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Algorithm::Classifier::NaiveBayes


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Classifier-NaiveBayes>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Algorithm-Classifier-NaiveBayes>

=item * Search CPAN

L<https://metacpan.org/release/Algorithm-Classifier-NaiveBayes>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Algorithm::Classifier::NaiveBayes

#!perl
# Shows how the tokenizer options passed to new affect what actually
# ends up in the model. The same string is trained under different
# settings and then classes and class_tokens are used to display the
# tokens stored for each class.
use strict;
use warnings;
use Algorithm::Classifier::NaiveBayes;

my $string = 'The Cat Sat At The Door';

# the defaults... split on whitespace and lowercase everything
my $default = Algorithm::Classifier::NaiveBayes->new;

# keep the case of tokens
my $no_lc = Algorithm::Classifier::NaiveBayes->new( 'lc_tokens' => 0 );

# drop some common stop words... matched against the whole token
my $stop = Algorithm::Classifier::NaiveBayes->new( 'stop_regex' => qr/a|an|and|at|the|of|to/ );

# split on something other than whitespace
my $csv = Algorithm::Classifier::NaiveBayes->new( 'token_splitter' => '\s*,\s*' );

my %classifiers = (
	'default'        => $default,
	'lc_tokens=0'    => $no_lc,
	'stop_regex'     => $stop,
	'token_splitter' => $csv,
);

foreach my $name ( sort keys %classifiers ) {
	my $nb = $classifiers{$name};

	if ( $name eq 'token_splitter' ) {
		$nb->train( 'csv',   'foo, bar,baz , 42' );
		$nb->train( 'other', 'a, b' );
	} else {
		$nb->train( 'cats', $string );
		$nb->train( 'dogs', 'The Dog Ran To The Gate' );
	}

	print $name . "\n";
	foreach my $class ( $nb->classes ) {
		print '    ' . $class . ': ' . join( ', ', $nb->class_tokens($class) ) . "\n";
	}
} ## end foreach my $name ( sort keys %classifiers )

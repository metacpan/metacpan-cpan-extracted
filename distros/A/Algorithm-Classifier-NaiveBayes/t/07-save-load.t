#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp;

use Algorithm::Classifier::NaiveBayes;

my $nb = Algorithm::Classifier::NaiveBayes->new;
$nb->train( 'spam', 'buy cheap pills now cheap' );
$nb->train( 'ham',  'meeting at noon tomorrow' );
$nb->train( 'ham',  'lunch meeting tomorrow' );

my $dir       = File::Temp::tempdir( 'CLEANUP' => 1 );
my $save_file = $dir . '/model.json';

$nb->save($save_file);
ok( -f $save_file, 'save creates the file' );

my $loaded = Algorithm::Classifier::NaiveBayes->new;
$loaded->load($save_file);
is_deeply( $loaded->{'model'}, $nb->{'model'}, 'load round trips the model' );
is( $loaded->classify('buy cheap pills'), 'spam', 'loaded model classifies' );

# qr// Regexps are stringified on save
my $qr_nb = Algorithm::Classifier::NaiveBayes->new( 'stop_regex' => qr/at|a/ );
$qr_nb->train( 'ham', 'cat at a noon' );
$qr_nb->save($save_file);
my $qr_loaded = Algorithm::Classifier::NaiveBayes->new;
$qr_loaded->load($save_file);
is_deeply( [ $qr_loaded->tokenize('cat at a noon') ], [ 'cat', 'noon' ], 'qr// stop_regex survives save/load' );

# error handling
eval { $nb->save(); };
like( $@, qr/No file specified/, 'save with no file dies' );

eval { $nb->save( $dir . '/nonexistent/model.json' ); };
like( $@, qr/Failed to write/, 'save to an unwritable path dies' );

eval { $loaded->load(); };
like( $@, qr/No file specified/, 'load with no file dies' );

eval { $loaded->load( $dir . '/nonexistent.json' ); };
like( $@, qr/Failed to read/, 'load of a missing file dies' );

my $write_bad = sub {
	open( my $fh, '>', $save_file ) or die($!);
	print $fh $_[0];
	close($fh);
};

$write_bad->('this is not json');
eval { $loaded->load($save_file); };
like( $@, qr/as JSON/, 'load of non-JSON dies' );

$write_bad->('[1,2,3]');
eval { $loaded->load($save_file); };
like( $@, qr/did not parse to a hash/, 'load of a non-hash dies' );

my $header = '"format":"Algorithm::Classifier::NaiveBayes","version":1,';

$write_bad->( '{' . $header . '"total_docs":1}' );
eval { $loaded->load($save_file); };
like( $@, qr/is not a hash/, 'load with missing model hashes dies' );

$write_bad->( '{'
		. $header
		. '"class_counts":{},"token_counts":{},"class_totals":{},"tokens":{},"total_docs":"x","token_splitter":"\\\\s+"}'
);
eval { $loaded->load($save_file); };
like( $@, qr/not a whole number/, 'load with a bad total_docs dies' );

$write_bad->( '{' . $header . '"class_counts":{},"token_counts":{},"class_totals":{},"tokens":{},"total_docs":0}' );
eval { $loaded->load($save_file); };
like( $@, qr/token_splitter/, 'load with a missing token_splitter dies' );

$write_bad->( '{'
		. $header
		. '"class_counts":{},"token_counts":{},"class_totals":{},"tokens":{},"total_docs":0,"token_splitter":"("}' );
eval { $loaded->load($save_file); };
like( $@, qr/does not compile/, 'load with a non-compiling token_splitter dies' );

# failed loads do not clobber the current model
is( $loaded->classify('buy cheap pills'), 'spam', 'model unchanged after failed loads' );

done_testing;

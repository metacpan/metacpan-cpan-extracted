#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp;

use App::Cmd::Tester;
use Algorithm::Classifier::NaiveBayes::App;

my $app = 'Algorithm::Classifier::NaiveBayes::App';

my $dir   = File::Temp::tempdir( 'CLEANUP' => 1 );
my $model = $dir . '/model.json';

##
## train
##

my $result = test_app( $app => [ 'train', '-m', $model, '-c', 'spam', 'buy', 'cheap', 'pills', 'now' ] );
is( $result->error, undef, 'train runs' );
like( $result->stdout, qr/Trained "spam", 1 total documents/, 'train reports what it did' );
ok( -f $model, 'train creates the model file' );

$result = test_app( $app => [ 'train', '-m', $model, '-c', 'ham', 'meeting', 'at', 'noon', 'tomorrow' ] );
is( $result->error, undef, 'training a second class works' );
like( $result->stdout, qr/2 total documents/, 'total documents incremented' );

# creation only options are rejected on an existing model
$result = test_app( $app => [ 'train', '-m', $model, '-c', 'spam', '--ngrams', '2', 'foo' ] );
like( $result->error, qr/only be used when creating/, 'creation options rejected on a existing model' );

# missing -c
$result = test_app( $app => [ 'train', '-m', $model, 'foo' ] );
like( $result->error, qr/-c has not been specified/, 'train without -c errors' );

# -f reads the text from a file
my $text_file = $dir . '/text.txt';
open( my $fh, '>', $text_file ) or die($!);
print $fh "cheap watches for sale\n";
close($fh);

$result = test_app( $app => [ 'train', '-m', $model, '-c', 'spam', '-f', $text_file ] );
is( $result->error, undef, 'train -f runs' );
like( $result->stdout, qr/3 total documents/, 'train -f trained the document' );

$result = test_app( $app => [ 'train', '-m', $model, '-c', 'spam', '-f', $text_file, 'extra', 'args' ] );
like( $result->error, qr/-f and text args may not be used together/, 'train -f with text args errors' );

$result = test_app( $app => [ 'train', '-m', $model, '-c', 'spam', '-f', $dir . '/nonexistent.txt' ] );
like( $result->error, qr/is not a file or does not exist/, 'train -f with a missing file errors' );

$result = test_app( $app => [ 'untrain', '-m', $model, '-c', 'spam', '-f', $text_file ] );
is( $result->error, undef, 'untrain -f runs' );
like( $result->stdout, qr/2 total documents/, 'untrain -f untrained the document' );

$result = test_app( $app => [ 'untrain', '-m', $model, '-c', 'spam', '-f', $text_file, 'extra' ] );
like( $result->error, qr/-f and text args may not be used together/, 'untrain -f with text args errors' );

##
## classify
##

$result = test_app( $app => [ 'classify', '-m', $model, 'cheap', 'pills' ] );
is( $result->error, undef, 'classify runs' );
like( $result->stdout, qr/\Aspam\n/, 'classify prints the class' );

$result = test_app( $app => [ 'classify', '-m', $model, '-s', '-p', 'cheap', 'pills' ] );
like( $result->stdout, qr/scores:/, '-s prints scores' );
like( $result->stdout, qr/probs:/,  '-p prints probs' );

$result = test_app( $app => [ 'classify', '-m', $model, '--json', 'cheap', 'pills' ] );
like( $result->stdout, qr/"class"\s*:\s*"spam"/, '--json prints JSON' );

$result = test_app( $app => [ 'classify', '-m', $dir . '/nonexistent.json', 'foo' ] );
like( $result->error, qr/is not a file or does not exist/, 'classify with a missing model errors' );

##
## explain
##

$result = test_app( $app => [ 'explain', '-m', $model, 'cheap', 'meeting', 'pills' ] );
is( $result->error, undef, 'explain runs' );
like( $result->stdout, qr/spam, probability/,         'explain prints the class and probability' );
like( $result->stdout, qr/cheap pushed towards spam/, 'explain prints token pulls' );

##
## info
##

$result = test_app( $app => [ 'info', '-m', $model ] );
is( $result->error, undef, 'info runs' );
like( $result->stdout, qr/total_docs: 2/,      'info prints total_docs' );
like( $result->stdout, qr/spam: docs=1/,       'info prints per class stats' );
like( $result->stdout, qr/smoothing: laplace/, 'info prints settings' );

##
## tokens
##

$result = test_app( $app => [ 'tokens', '-m', $model, 'spam' ] );
is( $result->error, undef, 'tokens runs' );
like( $result->stdout, qr/^cheap$/m, 'tokens lists the class tokens' );

$result = test_app( $app => [ 'tokens', '-m', $model, '-c', 'spam' ] );
like( $result->stdout, qr/^cheap: 1$/m, 'tokens -c includes counts' );

$result = test_app( $app => [ 'tokens', '-m', $model ] );
like( $result->error, qr/No class specified/, 'tokens without a class errors' );

##
## prune
##

$result = test_app( $app => [ 'prune', '-m', $model, '2' ] );
is( $result->error, undef, 'prune runs' );
like( $result->stdout, qr/Pruned 8 tokens, 0 remaining/, 'prune reports what it did' );

$result = test_app( $app => [ 'prune', '-m', $model, 'x' ] );
like( $result->error, qr/not a whole number/, 'prune with a bad min count errors' );

##
## tweak
##

$result = test_app( $app => [ 'tweak', '-m', $model, '--smoothing', 'lidstone', '--alpha', '0.1' ] );
is( $result->error, undef, 'tweak runs' );
like( $result->stdout, qr/smoothing: lidstone/, 'tweak reports the smoothing' );
like( $result->stdout, qr/alpha: 0.1/,          'tweak reports the alpha' );

$result = test_app( $app => [ 'info', '-m', $model ] );
like( $result->stdout, qr/smoothing: lidstone/, 'tweak changes are saved to the model' );

$result = test_app( $app => [ 'tweak', '-m', $model, '--priors', 'uniform' ] );
is( $result->error, undef, 'tweak priors runs' );
like( $result->stdout, qr/alpha: 0.1/, 'tweaking priors leaves alpha alone' );

$result = test_app( $app => [ 'tweak', '-m', $model ] );
like( $result->error, qr/Nothing to change/, 'tweak with nothing to change errors' );

$result = test_app( $app => [ 'tweak', '-m', $model, '--smoothing', 'derp' ] );
like( $result->error, qr/smoothing must be either/, 'tweak with a bad smoothing errors' );

##
## untrain
##

$result = test_app( $app => [ 'untrain', '-m', $model, '-c', 'ham', 'meeting', 'at', 'noon', 'tomorrow' ] );
is( $result->error, undef, 'untrain runs' );
like( $result->stdout, qr/Untrained "ham", 1 total documents/, 'untrain reports what it did' );

$result = test_app( $app => [ 'info', '-m', $model ] );
unlike( $result->stdout, qr/ham: docs/, 'untrained class no longer listed by info' );

done_testing;

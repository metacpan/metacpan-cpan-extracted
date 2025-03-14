use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;
use LWP::Simple;

use FindBin qw($Bin);

my $html_path = "$Bin/html/";
my $test_url = 'https://rawgit.com/kamelkev/CSS-Inliner/master/t/html/embedded_style.html';
my $result_file = $html_path . 'embedded_style_result.html';

open( my $fh, $result_file ) or die "can't open $result_file: $!!\n";
my $correct_result = do { local( $/ ) ; <$fh> } ;

my $inliner = CSS::Inliner->new();

eval {
  $inliner->fetch_file({ url => $test_url });
};

## conditional test plan based on whether or not the endpoint can be reached - frequently can't by cpan testers
plan $@ ? (skip_all => 'Connectivity for endpoint required for test cannot be established') : (tests => 2);

my $inlined = $inliner->inlinify();

ok($inlined eq $correct_result, 'result was correct');

$result_file = $html_path . 'embedded_style_result_encoded.html';

open( $fh, $result_file ) or die "can't open $result_file: $!!\n";
$correct_result = do { local( $/ ) ; <$fh> } ;

$inliner = CSS::Inliner->new({encode_entities => 1});

eval {
  $inliner->fetch_file({ url => $test_url });
};

$inlined = $inliner->inlinify();

ok($inlined eq $correct_result, 'result was correct');

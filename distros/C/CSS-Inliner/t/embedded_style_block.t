use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;
use LWP::Simple;

use FindBin qw($Bin);

eval {
  get('http://rawgit.com') or die $@;
};

# conditional test plan based on whether or not the endpoint can be reached - frequently can't by cpan testers
plan $@ ? (skip_all => 'Connectivity for endpoint required for test cannot be established') : (tests => 1);

my $html_path = "$Bin/html/";
my $test_url = 'http://rawgit.com/kamelkev/CSS-Inliner/master/t/html/embedded_style.html';
my $result_file = $html_path . 'embedded_style_result.html';

open( my $fh, $result_file ) or die "can't open $result_file: $!!\n";
my $correct_result = do { local( $/ ) ; <$fh> } ;

my $inliner = CSS::Inliner->new();
$inliner->fetch_file({ url => $test_url });
my $inlined = $inliner->inlinify();

ok($inlined eq $correct_result, 'result was correct');

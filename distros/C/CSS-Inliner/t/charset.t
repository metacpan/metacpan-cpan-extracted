use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;

use FindBin qw($Bin);

plan(tests => 1);

my $html_path = "$Bin/html/";
my $test_file = $html_path . 'charset.html';
my $result_file = $html_path . 'charset_result.html';

open(my $fh, '<:utf8', $result_file) or die "can't open $result_file: $!!\n";
my $correct_result = do { local( $/ ) ; <$fh> } ;

my $inliner = CSS::Inliner->new();
$inliner->read_file({ filename => $test_file, charset => 'utf8' });
my $inlined = $inliner->inlinify();

ok($inlined eq $correct_result, 'result was correct');

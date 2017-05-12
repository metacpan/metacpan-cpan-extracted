use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
use Cwd;
use CSS::Inliner;

use FindBin qw($Bin);

plan(tests => 2);

my @warnings = ();
BEGIN { $SIG{'__WARN__'} = sub { push @warnings, $_[0] } }

my $html_path = "$Bin/html/";
my $test_file = $html_path . 'pseudotest.html';
my $result_file = $html_path . 'pseudotest_result.html';

open( my $fh, $test_file ) or die "can't open $test_file: $!!\n";
my $html = do { local( $/ ) ; <$fh> } ;

open( my $fh2, $result_file ) or die "can't open $result_file: $!!\n";
my $correct_result = do { local( $/ ) ; <$fh2> } ;

my $inliner = CSS::Inliner->new();
$inliner->read({ html => $html });
my $inlined = $inliner->inlinify();

ok(scalar @warnings == 0, 'no warnings found');

ok($inlined eq $correct_result, 'result was correct');

#!perl -T
################################################################################
# some tests for helper functions
#
################################################################################

################################################################################

BEGIN{
    use Test::More;
    use Test::NoWarnings;
    use lib 't';
    use BioGrepSkip;
    my ($skip,$msg) = BioGrepSkip::skip_all( );
    plan skip_all => $msg if $skip;
}
plan tests => 30;

use BioGrepTest;

use Scalar::Util qw/tainted/;
use Cwd;

my @paths = ( '', '/', '/usr/local/bin' );

my $sbe = Bio::Grep->new();

my $result = Bio::Grep::SearchResult->new();

# todo make this platform independent
is( $sbe->_cat_path_filename( $paths[0], 't.txt' ), 't.txt', 'concat path' );

my $tainted_word    = 'bla' . substr( cwd, 0, 0 );
my $tainted_integer = '1' . substr( cwd,   0, 0 );
my $tainted_real    = '1.1' . substr( cwd, 0, 0 );

ok( tainted $tainted_word,    $tainted_word . ' tainted' );
ok( tainted $tainted_integer, $tainted_integer . ' tainted' );
ok( tainted $tainted_real,    $tainted_real . ' tainted' );

my $not_tainted_integer = $sbe->is_integer($tainted_integer);
ok( !tainted $not_tainted_integer, $not_tainted_integer . ' not tainted' );
my $not_tainted_word = $sbe->is_word($tainted_word);
ok( !tainted $not_tainted_word, $not_tainted_word . ' not tainted' );

is( $sbe->is_integer('1234'), 1234 );
eval { $sbe->is_integer('1234.5'); };
ok($EVAL_ERROR);
eval { $sbe->is_integer('10 && ls *'); };
ok($EVAL_ERROR);
is( $sbe->is_integer(undef), undef );


is( $sbe->is_word('1234'),           1234 );
is( $sbe->is_word('1234-valid.txt'), '1234-valid.txt' );
is( $sbe->is_word('1234-valid.txt_'), '1234-valid.txt_' );
eval { $sbe->is_word('valid && ls *'); };
ok($EVAL_ERROR);

eval { $sbe->is_arrayref_of_size('',2) };
cmp_ok($EVAL_ERROR, '=~', qr{Argument is not an array reference}, 
    'not an aref' );
eval { $sbe->is_arrayref_of_size({},2) };
cmp_ok($EVAL_ERROR, '=~', qr{Argument is not an array reference}, 
    'not an aref' );
eval { $sbe->is_arrayref_of_size([],2) };
cmp_ok($EVAL_ERROR, '=~', qr{Size of argument is too small}, 
    'Size of argument is too small' );

eval { $sbe->is_arrayref_of_size([ 'a', 'b', 'c' ],2) };
ok(!$EVAL_ERROR, 'ok' ) || diag $EVAL_ERROR;

no warnings;
eval {$sbe->_check_variable()};
cmp_ok($EVAL_ERROR, '=~', qr{Missing arguments: require hash with keys},
    "Exception with missing argument") || diag $EVAL_ERROR;
use warnings;
eval {$sbe->_check_variable( bla => 1 )};
cmp_ok($EVAL_ERROR, '=~', qr{Missing arguments: require hash with keys},
    "Exception with missing argument") || diag $EVAL_ERROR;

eval {$sbe->_check_variable( variable => 'bla',  regex => 'real' )};
cmp_ok($EVAL_ERROR, '=~', qr{Unknown regex},
    "Exception with unknown regex");

eval {$sbe->is_path('C:\My Programs', 'windows') };
ok(!$EVAL_ERROR, 'windows path ok') || diag $EVAL_ERROR;

$sbe=Bio::Grep->new('GUUGle');

ok($sbe->_rnas_match('agcua','agcua'), 'rna matching function');
ok(!$sbe->_rnas_match('agcuag','agcua'), 'rna matching function');
ok($sbe->_rnas_match('uguggu','cgcgau'), 'rna matching function');
ok($sbe->_rnas_match('uguggu','ugcggu'), 'rna matching function');
ok($sbe->_rnas_match('uguggu','cguggu'), 'rna matching function');
ok(!$sbe->_rnas_match('uguggu','cgcguu'), 'rna matching function');

my $tmp = $sbe->settings->tmppath;
$sbe->settings->datapath('data');
$sbe->settings->database('Test_DB_Big.fasta');
$sbe->settings->reverse_complement(1);

my $settings_dump =<<EOT
\$VAR1 = bless( {                               
                 'datapath' => 'data',
                 'no_alignments' => 0,
                 'execpath' => '',
                 'database' => 'Test_DB_Big.fasta',
                 'deletions' => '0',
                 'upstream' => '0',
                 'insertions' => '0',
                 'reverse_complement' => 1,
                 'direct_and_rev_com' => '',
                 'tmppath' => '$tmp',
                 'mismatches' => '',
                 'downstream' => '0',
                 'gumismatches' => 0
               }, 'Bio::Grep::SearchSettings' );
EOT
;

is_deeply(d2h($sbe->settings->to_string), d2h($settings_dump), 'Settings dump ok');
sub d2h {
    my ( $dump ) = @_;
    my %h;
    while ( $dump =~ m{ ^ \s+ '(.*?)' .*? > \s (.*?) [,]* $ }xmsg ) {
        my ($v1, $v2) = ($1, $2);
        $v2 =~ s/\'//g;
        $v2 = '' if !$v2;
        chomp $v2;
        $h{$v1} = $v2;
    }
    return \%h;
}

# vim: ft=perl sw=4 ts=4 expandtab

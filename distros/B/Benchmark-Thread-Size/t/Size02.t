BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 11;
use strict;
use warnings;

my $file = "testfile";
ok( open( my $handle,'>',$file ),	'open script file' );
ok( (print $handle <<EOD),		'write script' );
BEGIN { \@INC = qw(@INC) };
use Benchmark::Thread::Size times => 1, 'refonly';
EOD

ok( close( $handle ),			'close script' );
ok( -s $file,				'check whether script exists' );

foreach ($file,'-Ilib -MBenchmark::Thread::Size=times,1') {
    $/ = undef;
    ok( open( my $report,"$^X $file |" ),	'run the test' );
    my $text = <$report>;
    ok( $text =~ m/#   \(ref\)\s+
  0\s+\d+\s+
  1\s+\d+\s+
  2\s+\d+\s+
  5\s+\d+\s+
 10\s+\d+\s+
 20\s+\d+\s+
 50\s+\d+\s+
100\s+\d+\s+

==================================================================
/s, 'check the report' ) or warn "'$text'\n";
    ok( close( $report ),			'close report' );
}
ok( unlink( $file ),			'unlink script' );

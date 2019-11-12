BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 8;
use strict;
use warnings;

my $file = "testfile";
ok( open( my $handle,'>',$file ),	'open script file' );
ok( (print $handle <<EOD),		'write script' );
BEGIN { \@INC = qw(@INC) };
use Benchmark::Thread::Size times=>2, shared0 => <<'EOD1', shared1 => <<'EOD2';
use threads::shared ();
EOD1
use threads::shared;
EOD2
EOD

ok( close( $handle ),			'close script' );
ok( -s $file,				'check whether script exists' );

$/ = undef;
ok( open( my $report,"$^X $file |" ),	'run the test' );
my $text = <$report>;
ok( $text =~ m/#   \(ref\)     shared0     shared1\s+
  0\s+\d+ ...\s+[+\-\d]+ ...\s+[+\-\d]+ ...
  1\s+\d+ ...\s+[+\-\d]+ ...\s+[+\-\d]+ ...
  2\s+\d+ ...\s+[+\-\d]+ ...\s+[+\-\d]+ ...
  5\s+\d+ ...\s+[+\-\d]+ ...\s+[+\-\d]+ ...
 10\s+\d+ ...\s+[+\-\d]+ ...\s+[+\-\d]+ ...
 20\s+\d+ ...\s+[+\-\d]+ ...\s+[+\-\d]+ ...
 50\s+\d+ ...\s+[+\-\d]+ ...\s+[+\-\d]+ ...
100\s+\d+ ....?\s+[+\-\d]+ ....?\s+[+\-\d]+ ....?

==== shared0 =====================================================
use threads::shared \(\);

==== shared1 =====================================================
use threads::shared;

==================================================================
/s,					'check the report' ) or warn "'$text'\n";

ok( close( $report ),			'close report' );

ok( unlink( $file ),			'unlink script' );

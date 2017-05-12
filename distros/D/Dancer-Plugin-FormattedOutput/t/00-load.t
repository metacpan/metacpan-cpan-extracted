#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::FormattedOutput' ) || print "Bail out!
";
}

diag( "Testing Dancer::Plugin::FormattedOutput $Dancer::Plugin::FormattedOutput::VERSION, Perl $], $^X" );

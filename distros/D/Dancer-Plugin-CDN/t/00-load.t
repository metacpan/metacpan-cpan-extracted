
use Test::More tests => 1;

use Dancer::Plugin::CDN;

ok(1, "Successfully loaded Dancer::Plugin::CDN via 'use'");

diag( "Testing Dancer::Plugin::CDN $Dancer::Plugin::CDN::VERSION, Perl $], $^X" );

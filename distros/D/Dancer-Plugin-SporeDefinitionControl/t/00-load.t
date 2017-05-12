#!perl

use FindBin;
BEGIN { $ENV{DANCER_APPDIR} = $FindBin::Bin }

use Test::More tests => 1, import => ['!pass'];

use Dancer;

BEGIN {
  set plugins => {
    SporeDefinitionControl => {
      spore_spec_path => "sample_route.yaml",
    },
  };
}
use_ok( 'Dancer::Plugin::SporeDefinitionControl' ) || print "Bail out!";

diag( "Testing Dancer::Plugin::SporeDefinitionControl $Dancer::Plugin::SporeDefinitionControl::VERSION, Perl $], $^X" );

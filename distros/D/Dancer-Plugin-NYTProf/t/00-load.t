#!perl

use Dancer;
use Test::More;
use File::Which;

BEGIN {
    # If nytprofhtml isn't found, the module can't do anything so fails to load
    # - so check that first of all
    my $nytprofhtml_path = File::Which::which('nytprofhtml');
    if (!$nytprofhtml_path) {
        plan skip_all => "nytprofhtml not found in path, cannot continue";
    } else {
        plan tests => 1;
        use Dancer qw(:syntax);
        use_ok( 'Dancer::Plugin::NYTProf' ) or print "Bail out!\n";
    }
}

diag( "Testing Dancer::Plugin::NYTProf $Dancer::Plugin::NYTProf::VERSION, Perl $], $^X" );

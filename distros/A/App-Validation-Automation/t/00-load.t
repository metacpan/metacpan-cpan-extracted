#!perl -T
use lib qw(
    /home/vj504j/App-Validation-Automation-0.01/lib /home/vj504j/perllib 
);
use Test::More tests => 1;

BEGIN {
    use_ok( 'App::Validation::Automation' ) || print "Bail out!\n";
}

diag( "Testing App::Validation::Automation $App::Validation::Automation::VERSION, Perl $], $^X" );

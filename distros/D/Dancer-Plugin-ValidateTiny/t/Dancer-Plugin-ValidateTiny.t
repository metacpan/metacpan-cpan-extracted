use Test::More tests => 1;

BEGIN {
	use_ok('Dancer::Plugin::ValidateTiny') || print "Bail out!
";
}
 
diag( "Dancer::Plugin::ValidateTiny $Dancer::Plugin::ValidateTiny::VERSION, Perl $], $^X" );
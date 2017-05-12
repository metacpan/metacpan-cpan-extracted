use Test::More tests => 1;

BEGIN {
    use_ok( 'Dancer::Plugin::Log::DB' ) || print "Bail out!\n";
}

diag( "Testing Dancer::Plugin::Log::DB $Dancer::Plugin::Log::DB::VERSION, Perl $], $^X" );

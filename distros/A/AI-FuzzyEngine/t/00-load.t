use Test::More tests => 3;

BEGIN {
    use_ok( 'AI::FuzzyEngine'           ) || print "Bail out!\n";
    use_ok( 'AI::FuzzyEngine::Variable' ) || print "Bail out!\n";
    use_ok( 'AI::FuzzyEngine::Set'      ) || print "Bail out!\n";
}

# diag( "Testing AI::FuzzyEngine $AI::FuzzyEngine::VERSION, Perl $], $^X" );

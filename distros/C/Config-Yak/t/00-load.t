#!perl -T

use Test::More tests => 5;

BEGIN {
    use_ok( 'Config::Yak::LazyConfig' ) || print "Bail out!
";
    use_ok( 'Config::Yak::NamedPlugins' ) || print "Bail out!
";
    use_ok( 'Config::Yak::OrderedPlugins' ) || print "Bail out!
";
    use_ok( 'Config::Yak::RequiredConfig' ) || print "Bail out!
";
    use_ok( 'Config::Yak' ) || print "Bail out!
";
}

diag( "Testing Config::Yak $Config::Yak::VERSION, Perl $], $^X" );

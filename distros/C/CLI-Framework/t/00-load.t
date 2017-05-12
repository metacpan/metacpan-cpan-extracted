use Test::More tests => 6;

use lib 'lib';
use lib 't/lib';

BEGIN {
    use_ok( 'CLI::Framework' );
    use_ok( 'CLI::Framework::Application' );
    use_ok( 'CLI::Framework::Command' );
    use_ok( 'CLI::Framework::Command::Help' );
    use_ok( 'CLI::Framework::Command::List' );
    use_ok( 'CLI::Framework::Command::Menu' );
}

diag( "Testing CLI::Framework::Application $CLI::Framework::Application::VERSION, Perl $], $^X" );

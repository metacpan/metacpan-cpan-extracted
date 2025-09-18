use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok('App::GitKtti');
}

# Test color constants
ok(defined App::GitKtti::RESET, 'RESET constant defined');
ok(defined App::GitKtti::BOLD, 'BOLD constant defined');
ok(defined App::GitKtti::BRIGHT_GREEN, 'BRIGHT_GREEN constant defined');

# Test utility functions
can_ok('App::GitKtti', qw(
    printSuccess
    printError
    printWarning
    printInfo
    showLogo
    showVersion
    LPad
    RPad
    trim
));

done_testing();

use Test::More tests => 1;
BEGIN { use_ok('Alarm') }

diag("Testing Catalyst::Plugin::Alarm $Catalyst::Plugin::Alarm::VERSION");

eval {
    require Sys::SigAction;
    diag("Testing Sys::SigAction $Sys::SigAction::VERSION");
};

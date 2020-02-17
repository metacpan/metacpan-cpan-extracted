use strict;
use warnings;
use Test::More;

# Put in the cpantesters report whether IPC::System::Simple was present.
my $mod = 'IPC::System::Simple';
eval "require $mod";
my $err = $@;

if($err) {
    diag "Could not require $mod:\n$err";
} else {
    diag "Successfully required $mod, ver. " . $IPC::System::Simple::VERSION;
}

ok 1, 'Nothing to test here!';
    # I don't want this to cause test failure --- I want to be able to use
    # this to cross-check the existing test failures.
done_testing;

use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::patchelf;

UTILITY:
{
    diag 'Testing Alien::patchelf version: ' . Alien::patchelf->version;
    my ($result, $stderr, $exit) = Alien::patchelf->patchelf ("--help");
    like ($stderr, qr{^syntax\:\s.*patchelf},
        'Got expected first line from patchelf utility');
    diag '';
    diag ("\nUtility results:\n" . $result);
    diag ($stderr) if $stderr;
    diag "Exit code is $exit";
    diag '';
}

done_testing();


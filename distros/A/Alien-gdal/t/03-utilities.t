use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::gdal;

diag "LD_LIBRARY_PATH: "   . ($ENV{LD_LIBRARY_PATH} // '');
diag "DYLD_LIBRARY_PATH: " . ($ENV{DYLD_LIBRARY_PATH} // '');

TODO:
{
    local $TODO = 'possibly flaky in early release, but should not stop installation';
    my ($result, $stderr, $exit) = Alien::gdal->run_utility ("gdalwarp", '--version');
    like ($result, qr{GDAL \d+\.\d+\.\d+, released \d{4}/\d{2}/\d{2}},
        'Got expected result from gdalwarp utility');
    diag '';
    diag ("\nUtility results:\n" . $result);
    diag ($stderr) if $stderr;
    diag "Exit code is $exit";
    diag '';
}

done_testing();


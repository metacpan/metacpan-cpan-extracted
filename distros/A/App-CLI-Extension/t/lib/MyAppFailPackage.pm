package MyAppFailPackage;

use strict;
use base qw(App::CLI::Extension);
use constant alias => (
                raiseerror      => "RaiseError",
            );

$ENV{APPCLI_NON_EXIT} = 1;

1;


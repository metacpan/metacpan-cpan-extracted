package MyAppFinish;

use strict;
use base qw(App::CLI::Extension);
use constant alias => (
                finished      => "Finished",
            );

$ENV{APPCLI_NON_EXIT} = 1;

1;


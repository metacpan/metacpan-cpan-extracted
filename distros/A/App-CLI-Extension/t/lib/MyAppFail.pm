package MyAppFail;

use strict;
use base qw(App::CLI::Extension);
use constant alias => (
                fail      => "FailTest",
            );

$ENV{APPCLI_NON_EXIT} = 1;
__PACKAGE__->load_plugins(qw(
                         +MyAppFail::Plugin::Fail
));

1;


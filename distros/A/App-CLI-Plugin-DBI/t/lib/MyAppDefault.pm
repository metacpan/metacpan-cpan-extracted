package MyAppDefault;

use strict;
use base qw(App::CLI::Extension);
use constant alias => (
                 main             => "Main",
				 changehandlename => "ChangeHandleName",
             );

$ENV{APPCLI_NON_EXIT} = 1;
__PACKAGE__->config(dbi => ['dbi:Mock:', '', '']);
__PACKAGE__->load_plugins(qw(DBI));

1;

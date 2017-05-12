package MyAppMulti;

use strict;
use base qw(App::CLI::Extension);
use constant alias => (
                 main => "Main",
             );

$ENV{APPCLI_NON_EXIT} = 1;
__PACKAGE__->config(dbi => { 
						other1 => ['dbi:Mock:dbname=test1', '', ''], 
						other2 => ['dbi:Mock:dbname=test2', '', ''], 
					}
				);
__PACKAGE__->load_plugins(qw(DBI));

1;

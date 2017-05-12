use strict;
use Test::More tests => 2;

BEGIN { use_ok 'App::pfswatch' }
my @method = qw/
    new new_with_options run ignored_pattern parse_argv
/;
can_ok 'App::pfswatch', @method;

#! perl

use Test::More;

use CLI::Osprey::Descriptive::Usage;

ok 'CLI::Osprey::Descriptive::Usage'->can($_), "can_ok $_" for (
       'new',
       'text',
       'leader_text',
       'warn',
       'die',

       # option_text() is part of the Getopt::Long::Descriptive::Usage API, but
       # seems only to be used within ::Usage, so maybe it doesn't need
       # to be implemented?
       # 'option_text',
);


done_testing;

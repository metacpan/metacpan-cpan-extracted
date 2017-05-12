use strict;
use warnings;

use Test::More;

unless($ENV{RELEASE_TESTING}) {
    plan( skip_all => "Author tests not required for installation" );
}

eval { require Test::Kwalitee; };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

Test::Kwalitee->import();

unlink 'Debian_CPANTS.txt' if -e 'Debian_CPANTS.txt';

# 01-Changes.t - Test file for CPANPLUS::Shell::Default::Plugins::Changes

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib';
}

use strict;
use Test::More 'no_plan';

my $Class = 'CPANPLUS::Shell::Default::Plugins::Changes';
my $Plugins  = 'plugins';

use_ok($Class);
can_ok($Class, $Plugins);

{
    my %map = $Class->$Plugins;
    isa_ok(\%map, 'HASH');

    for my $method (values %map) {
        can_ok($Class, $method);
        can_ok($Class, $method . '_help');
    }
}

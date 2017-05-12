use strict;
use warnings;
use utf8;
use Test::More;
use File::Find qw(find);

my @module;
find sub {
    local $_ = $File::Find::name;
    return unless s{\.pm$}{};
    s{^lib/}{}; s{/}{::}g;
    push @module, $_;
}, "lib";

use_ok $_ for @module;
ok system("$^X -wc script/change-shebang") == 0;

done_testing;


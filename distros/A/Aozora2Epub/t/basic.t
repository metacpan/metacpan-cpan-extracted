use strict;
use Test::More;
use File::Find;

sub use_pm {
    my $f = $File::Find::name;
    return unless $f =~ m{lib/([\w/]+)\.pm$};
    my $mod = $1;
    $mod =~ s{/}{::}sg;
    use_ok $mod;
}

find(\&use_pm, "./lib");

done_testing;


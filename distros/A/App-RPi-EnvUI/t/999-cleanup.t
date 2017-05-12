use strict;
use warnings;
use Test::More;

my $tfile = 't/envui.db';
my $cfile = 't/envui.json';
my $lfile = 't/testing.lck';

ok 1, "cleanup test loaded ok";

for ($tfile, $cfile, $lfile){
    if (-e $_){
        unlink $_ or die $!;
        is -e $_, undef, "$_ temp test file removed ok";
    }
}

done_testing();


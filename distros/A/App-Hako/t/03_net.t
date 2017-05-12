use strict;
use Test::More 0.98;
use File::Temp;

# We want to run the script, which we are probably still building.
$ENV{PATH} = "blib/script:$ENV{PATH}";

my $box = File::Temp->newdir;
my $cmd = "/sbin/ip -o link list";
my @links;

# sanity check: make sure we have more than one network link
@links = qx{$cmd};
is $?>>8, 0, "ip link works with no error";
ok @links > 1, "more than one net link outside";

my $n = @links;

@links = qx{hako $box $cmd};
is $?>>8, 0, "no error";
is @links, $n, "same number of net links inside the regular box";

@links = qx{hako -n $box $cmd};
is $?>>8, 0, "no error";
is @links, 1, "just one net link inside the isolated box";

done_testing;


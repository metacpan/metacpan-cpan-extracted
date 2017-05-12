use strict;
use Test::More 0.98;
use File::Temp;

# We want to run the script, which we are probably still building.
$ENV{PATH} = "blib/script:$ENV{PATH}";

my $box = File::Temp->newdir;

my $ls;

$ls = qx{hako $box ls};
is $?>>8, 0, "no error";
is $ls, "", "empty dir";

$ls = qx{hako $box ls $ENV{HOME}};
is $?>>8, 0, "no error";
is $ls, "", "empty home";

system "hako $box touch Cat";

ok -f "$box/Cat", "The Cat is in the box";
ok ! -f "$ENV{HOME}/Cat", "The Cat is not at home";

$ls = qx{hako $box ls $ENV{HOME}};
is $?>>8, 0, "no error";
chomp $ls;
is $ls, "Cat", "The Cat in the box is at home";

done_testing;


use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::PubSub::Shared::Int;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.ps');
close $fh;

{
    my $p = Data::PubSub::Shared::Int->new($path, 64);
    $p->publish(42);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::PubSub::Shared::Int->new($path, 64) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;

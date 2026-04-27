use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Stack::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.stk');
close $fh;

{
    my $s = Data::Stack::Shared::Int->new($path, 16);
    $s->push(42);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::Stack::Shared::Int->new($path, 16) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Graph::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.graph');
close $fh;

{
    my $g = Data::Graph::Shared->new($path, 32, 64);
    $g->add_node(0);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::Graph::Shared->new($path, 32, 64) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::Buffer::Shared::I64;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.buf');
close $fh;

{
    my $b = Data::Buffer::Shared::I64->new($path, 16);
    $b->set(0, 42);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::Buffer::Shared::I64->new($path, 16) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small|corrupt/i, "meaningful error";

done_testing;

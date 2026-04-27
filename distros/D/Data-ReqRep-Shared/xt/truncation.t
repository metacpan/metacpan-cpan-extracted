use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::ReqRep::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.rr');
close $fh;

{
    my $r = Data::ReqRep::Shared->new($path, 8, 4, 128);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::ReqRep::Shared->new($path, 8, 4, 128) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/invalid|incompatible|too small/i, "meaningful error";

done_testing;

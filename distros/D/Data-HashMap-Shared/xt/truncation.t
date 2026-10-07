use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use Data::HashMap::Shared::II;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.shm');
close $fh;

{
    my $m = Data::HashMap::Shared::II->new($path, 64);
    $m->put(1, 100);
}

my $sz = -s $path;
truncate($path, $sz - 1) or die;

my $r = eval { Data::HashMap::Shared::II->new($path, 64) };
ok !$r, "reopen of truncated file rejected";
like $@, qr/the file is @{[ $sz - 1 ]} bytes but its header says $sz/, "meaningful error, naming both sizes";

done_testing;

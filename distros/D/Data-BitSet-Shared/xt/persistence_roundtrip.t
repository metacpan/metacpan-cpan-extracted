use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Digest::SHA qw(sha256_hex);

use Data::BitSet::Shared;

my ($fh, $path) = tempfile(UNLINK => 1, SUFFIX => '.bs');
close $fh;

{
    my $b = Data::BitSet::Shared->new($path, 256);
    $b->set($_) for (5, 17, 31, 63, 127, 200);
    $b->sync;
}

my $sz = -s $path;
ok $sz > 0, "file exists";
my $sha1 = sha256_hex(do { open my $f, '<', $path; binmode $f; local $/; <$f> });

{
    my $b = Data::BitSet::Shared->new($path, 256);
    $b->sync;
}
my $sha2 = sha256_hex(do { open my $f, '<', $path; binmode $f; local $/; <$f> });
is $sha2, $sha1, "byte-identical after reopen+sync";

{
    my $b = Data::BitSet::Shared->new($path, 256);
    for my $bit (5, 17, 31, 63, 127, 200) {
        ok $b->test($bit), "bit $bit persisted";
    }
}

done_testing;

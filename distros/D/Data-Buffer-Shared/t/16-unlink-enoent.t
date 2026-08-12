use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::Buffer::Shared::I64;

# unlink croaks when a removal genuinely fails, but "already gone" is what the
# caller asked for -- a cleanup path run twice, or racing another process,
# should not die for it.

my $dir = tempdir( CLEANUP => 1 );
my $sub = "$dir/holder";
mkdir $sub or die "mkdir: $!";
my $p = "$sub/f.i64";

my $b = Data::Buffer::Shared::I64->new( $p, 128 );
ok -e $p, 'backing file created';

$b->unlink;
ok !-e $p, 'unlink removes the file';

my $twice = eval { $b->unlink; 1 };
ok $twice, 'a second unlink is benign (ENOENT)' or diag $@;

my $cls = eval { Data::Buffer::Shared::I64->unlink("$sub/never-existed.bin"); 1 };
ok $cls, 'class-form unlink of a nonexistent path is benign' or diag $@;

SKIP: {
    skip 'run as root: permission checks do not apply', 2 if $> == 0;
    my $q = "$sub/g.i64";
    my $h = Data::Buffer::Shared::I64->new( $q, 128 );
    chmod 0500, $sub or die "chmod: $!";
    my $lived = eval { $h->unlink; 1 };
    my $err   = $@;
    chmod 0700, $sub;
    ok !$lived, 'a removal that cannot happen still croaks';
    like $err, qr/unlink/, '  ... and the message names unlink' or diag "got: $err";
}

done_testing;

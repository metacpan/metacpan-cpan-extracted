use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Data::CountMinSketch::Shared;

# unlink() used to discard its return value, so a removal that could not happen
# reported success and quietly left the file behind. Make the removal fail by
# clearing write permission on the containing directory.

plan skip_all => 'run as root: permission checks do not apply' if $> == 0;

my $dir = tempdir( CLEANUP => 1 );
my $sub = "$dir/holder";
mkdir $sub or die "mkdir: $!";
my $p = "$sub/f.bin";

my $h = Data::CountMinSketch::Shared->new( $p, 0.001, 0.001 );
ok -e $p, 'backing file created';

chmod 0500, $sub or die "chmod: $!";          # r-x: entries cannot be removed
my $lived = eval { $h->unlink; 1 };
my $err   = $@;
chmod 0700, $sub;                              # restore so CLEANUP works

ok !$lived, 'unlink croaks when the file cannot be removed';
like $err, qr/unlink/, '  ... and the message names unlink'
    or diag "got: $err";
ok -e $p, 'the sketch file is still there, as the error said';

# and the ordinary case still succeeds
$h->unlink;
ok !-e $p, 'unlink removes the file when it can';

# Removing a file that is already gone achieved what the caller asked for:
# benign, not an error (a cleanup path run twice, or racing another process).
my $twice = eval { $h->unlink; 1 };
ok $twice, q{unlink on an already-removed file is benign (ENOENT)}
    or diag $@;
my $cls = eval { 'Data::CountMinSketch::Shared'->unlink("$sub/never-existed.bin"); 1 };
ok $cls, q{class-form unlink of a nonexistent path is benign}
    or diag $@;

done_testing;

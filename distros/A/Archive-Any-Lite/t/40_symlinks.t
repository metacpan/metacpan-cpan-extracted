use strict;
use warnings;
use FindBin;
use Test::More tests => 2 * 2;
use Archive::Any::Lite;
use File::Temp;

$Archive::Any::Lite::IGNORE_SYMLINK = 1;

for (qw/symlink_test.tar.gz symlink_test.zip/) {
    my $tmpdir = File::Temp->newdir;
    my $archive = Archive::Any::Lite->new("$FindBin::Bin/$_");
    $archive->extract($tmpdir);
    ok -f "$tmpdir/symlink_test/file.txt", "$_: file.txt exists";
    ok !-f "$tmpdir/symlink_test/symlink", "$_: symlink is ignored";
}

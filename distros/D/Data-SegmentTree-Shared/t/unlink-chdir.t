use strict;
use warnings;
use Test::More;
use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use Data::SegmentTree::Shared;
my $cwd = getcwd();
END { chdir $cwd if defined $cwd }
my $dir = tempdir(CLEANUP => 1);
mkdir "$dir/a" or die $!;
mkdir "$dir/b" or die $!;
for my $reopen (0, 1) {
    chdir "$dir/a" or die $!;
    my $h = Data::SegmentTree::Shared->new('backing', 8);
    if ($reopen) { undef $h; $h = Data::SegmentTree::Shared->new('backing', 8) }
    is $h->path, 'backing', 'path preserves the constructor argument';
    chdir "$dir/b" or die $!;
    open my $other, '>', 'backing' or die $!;
    print {$other} 'unrelated';
    close $other or die $!;
    $h->unlink;
    ok !-e "$dir/a/backing", 'original backing file is removed after chdir';
    ok -e 'backing', 'same name in the new directory is preserved';
    ok eval { $h->unlink; 1 }, 'repeated unlink remains harmless';
    $h->set(0, 42); is $h->get(0), 42, 'unlinked mapping stays usable';
}
chdir $cwd or die $!;
done_testing;

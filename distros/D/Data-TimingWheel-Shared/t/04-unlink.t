use strict;
use warnings;
use Test::More;
use Cwd qw(getcwd);
use File::Temp qw(tempdir);
use Data::TimingWheel::Shared;

my $cwd = getcwd();
END { chdir $cwd if defined $cwd }
my $dir = tempdir(CLEANUP => 1);
mkdir "$dir/a" or die $!;
mkdir "$dir/b" or die $!;

for my $reopen (0, 1) {
    chdir "$dir/a" or die $!;
    my $tw = Data::TimingWheel::Shared->new('wheel.tw', 8, 1);
    if ($reopen) {
        undef $tw;
        $tw = Data::TimingWheel::Shared->new('wheel.tw', 1, 1);
    }
    is $tw->path, 'wheel.tw', 'path preserves the constructor argument';
    chdir "$dir/b" or die $!;
    open my $fh, '>', 'wheel.tw' or die $!;
    print {$fh} 'unrelated' or die $!;
    close $fh or die $!;
    $tw->unlink;
    ok !-e "$dir/a/wheel.tw", 'unlink removes the backing file after chdir';
    ok -e 'wheel.tw', 'unlink preserves the same name in the new directory';
    ok eval { $tw->unlink; 1 }, 'unlink of the removed backing file stays harmless';
    $tw->add(1, 42);
    is_deeply [$tw->advance], [42], 'unlinked mapping stays usable';
}
chdir $cwd or die $!;

done_testing;

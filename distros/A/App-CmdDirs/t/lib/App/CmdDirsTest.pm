use 5.12.0;
use warnings;

package App::CmdDirsTest;
use base qw(Test::Class);
use Cwd;
use File::Temp;
use Test::More;

use App::CmdDirs;

my $originalDir = cwd();

my $dir;
my $gitRepo = 'gitRepo';
my $svnRepo = 'svnRepo';

sub makeTestDir : Test(setup) {
    # Cleanup any existing dir
    cleanup();

    # Create teh tempdir & go there
    $dir = File::Temp->newdir();
    chdir $dir;

    makeDir($gitRepo, '.git');
    makeDir($svnRepo, '.svn');
}

# Create a directory within the temp dir with the given directory within
# e.g. to make a fake git repo: makeDir('gitrepo', '.git')
#
# Returns the directory created
sub makeDir {
    my ($name, $contents) = @_;
    my $dirname = $dir . "/$name";

    mkdir $dirname;
    mkdir $dirname . "/$contents";

    return $dirname;
}

# Leave the tmpdir so that it can be cleaned up
sub cleanup : Test(teardown) {
    chdir $originalDir;
    undef $dir;
}

sub testGit : Test(2) {
    my $testFile = 'git_repo_file';
    my @argv = ("touch $testFile");
    my $cmdDirs = App::CmdDirs->new(\@argv, {'quiet' => 1});
    $cmdDirs->run();
    ok(-f "$gitRepo/$testFile");
    ok(! -f "$svnRepo/$testFile");
}

sub testSvn : Test(2) {
    my $testFile = 'svn_repo_file';
    my @argv = ("touch $testFile");
    my $cmdDirs = App::CmdDirs->new(\@argv, {'quiet' => 1});
    $cmdDirs->run();
    ok(-f "$svnRepo/$testFile");
    ok(! -f "$gitRepo/$testFile");
}

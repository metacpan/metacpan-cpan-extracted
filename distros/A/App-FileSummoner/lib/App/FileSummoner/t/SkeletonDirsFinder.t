package App::FileSummoner::SkeletonDirsFinder::Test;

use Modern::Perl;
use base 'Test::Class';
use Test::More;

use App::FileSummoner::SkeletonDirsFinder;

sub findForFile {
    my ($path) = @_;
    return App::FileSummoner::SkeletonDirsFinder->new()->findForFile($path);
}

sub testFindForFile : Tests {
    is_deeply([ findForFile('/a/b/x.pm') ], [
        '/a/b/.skeletons',
        '/a/.skeletons',
        '/.skeletons',
    ], '/a/b');
}

Test::Class->runtests;

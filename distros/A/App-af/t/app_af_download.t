use Test2::V0 -no_srand => 1;
use App::af;
use lib 't/lib';
use MyTest;
use File::chdir;
use Path::Tiny qw( path );
use File::Temp qw( tempdir );
do './bin/af';

subtest 'file' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    use Path::Tiny qw( path );
    probe sub { 'system' };
    share {
      download sub {
        path('foo-1.00.tar.gz')->spew('some test data');
      };
    };
  };

  is(run('download'), 0);
  ok(-f "foo-1.00.tar.gz", "file was copied");
  is(path("foo-1.00.tar.gz")->slurp, "some test data", 'correct data');
  unlink 'foo-1.00.tar.gz';

  mkdir 'roger';

  is(run('download', '--local' => 'roger'), 0);
  ok(-f "roger/foo-1.00.tar.gz", "file was copied");
  ok(! -f "foo-1.00.tar.gz", "file was not copied");
  is(path("roger/foo-1.00.tar.gz")->slurp, "some test data", 'correct data');
  unlink 'roger/foo-1.00.tar.gz';
};

subtest 'directory' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    use Path::Tiny qw( path );
    probe sub { 'system' };
    share {
      download sub {
        path('dir1')->mkpath;
        path('dir1/file1')->spew('data 1');
        path('dir1/file2')->spew('data 2');
      };
    };
  };

  is(run('download'), 0);
  ok(-f 'dir1/file1');
  ok(-f 'dir1/file2');
  is(path('dir1/file1')->slurp, 'data 1');
  is(path('dir1/file2')->slurp, 'data 2');

};

subtest 'nada' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    use Path::Tiny qw( path );
    probe sub { 'system' };
    share {
      download sub {
      };
    };
  };

  is(run('download'), 2);

};

done_testing;

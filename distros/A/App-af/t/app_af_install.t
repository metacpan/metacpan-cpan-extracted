use Test2::V0 -no_srand => 1;
use App::af;
use lib 't/lib';
use MyTest;
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
do './bin/af';

delete $ENV{ALIEN_INSTALL_TYPE};

subtest 'basic' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  my $prefix = path('test-prefix')->absolute;

  alienfile q{
    use alienfile;
    use Path::Tiny qw( path );
    plugin 'Test::Mock',
      probe    => 'share',
      download => 1,
      extract  => 1;
    share {
      build sub {
        my($build) = @_;
        path($build->install_prop->{prefix})->child('file1')->touchpath;
        path($build->install_prop->{prefix})->child('file2')->touchpath;
      };
    };
  };

  run 'install', "--prefix=$prefix";

  is last_exit, 0;

  ok( -f $prefix->child('file1') );
  ok( -f $prefix->child('file1') );

};

subtest '--dry-run' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  my $stage = path('test-stage')->absolute;

  alienfile q{
    use alienfile;
    use Path::Tiny qw( path );
    plugin 'Test::Mock',
      probe    => 'share',
      download => 1,
      extract  => 1;
    share {
      build sub {
        my($build) = @_;
        path($build->install_prop->{prefix})->child('file1')->touchpath;
        path($build->install_prop->{prefix})->child('file2')->touchpath;
      };
    };
  };

  run 'install', "--dry-run", "--stage=$stage";

  is last_exit, 0;

  note "stage = $stage";
  ok( -f $stage->child('file1') );
  ok( -f $stage->child('file1') );

};

done_testing;

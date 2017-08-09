use Test2::Plugin::FauxHomeDir;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::Cache;
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

subtest 'basic' => sub {
  
  local $CWD = tempdir( CLEANUP => 1);

  $ENV{ALIEN_BUILD_PRELOAD} = 'Fetch::Cache';

  my $build = alienfile_ok q{
    use alienfile;
    use File::Temp qw( tempdir );
    use Path::Tiny qw( path );
    
    my $file2 = path(tempdir( CLEANUP => 1))->child('file2.txt');
    $file2->spew('content of file2');

    probe sub { 'share' };
    
    share {
    
      fetch sub {
        my($build, $url) = @_;
        $main::count++;
        
        if($url eq 'http://foo.test/file1.txt')
        {
          return {
            type     => 'file',
            filename => 'file1.txt',
            content  => 'content of file1',
          };
        }
        
        elsif($url eq 'http://foo.test/file2.txt')
        {
          return {
            type     => 'file',
            filename => 'file2.txt',
            path     => $file2->stringify,
          };
        }
        
        elsif($url eq 'http://foo.test/')
        {
          return {
            type => 'list',
            list => [
              { filename => 'file1.txt', url => 'http://foo.test/file1.txt' },
              { filename => 'file2.txt', url => 'http://foo.test/file2.txt' },
            ],
          };
        }
        
        else
        {
          die;
        }
      };
    
    };
  };
  
  my $fetch = sub 
  {
    my($url) = @_;
    my($output, $res) = capture_merged {
      $build->fetch($url);
    };
    note $output if $output ne '';
    $res;
  };

  subtest 'first index' => sub {

    $main::count = 0;

    my $res = $fetch->('http://foo.test/');
    is(
      $res,
      { type => 'list',
        list => [
          { filename => 'file1.txt', url => 'http://foo.test/file1.txt' },
          { filename => 'file2.txt', url => 'http://foo.test/file2.txt' },
        ],
      },
      'expected index',
    );
    
    is($main::count, 1, 'not cached' );

  };

  subtest 'second index' => sub {

    $main::count = 0;

    my $res = $fetch->('http://foo.test/');
    is(
      $res,
      { type => 'list',
        list => [
          { filename => 'file1.txt', url => 'http://foo.test/file1.txt' },
          { filename => 'file2.txt', url => 'http://foo.test/file2.txt' },
        ],
      },
      'expected index',
    );
    
    is($main::count, 0, 'cached' );

  };

  subtest 'second index inferred URL' => sub {

    $main::count = 0;
    local $build->meta_prop->{plugin_download_negotiate_default_url} = 'http://foo.test/';
    
    my $res = $fetch->();
    is(
      $res,
      { type => 'list',
        list => [
          { filename => 'file1.txt', url => 'http://foo.test/file1.txt' },
          { filename => 'file2.txt', url => 'http://foo.test/file2.txt' },
        ],
      },
      'expected index',
    );
    
    is($main::count, 0, 'cached' );

  };
  
  subtest 'first file1' => sub {

    $main::count = 0;

    my $res = $fetch->('http://foo.test/file1.txt');
    is(
      $res,
      hash {
        field type     => 'file';
        field filename => 'file1.txt';
        field content  => 'content of file1';
      },
      'expected file',
    );
    is(
      $main::count,
      1,
      'not cached'
    );
  };

  subtest 'second file1' => sub {

    $main::count = 0;

    my $res = $fetch->('http://foo.test/file1.txt');
    is(
      $res,
      hash {
        field type     => 'file';
        field filename => 'file1.txt';
        field path     => T();
      },
      'expected file',
    );
    is(
      path($res->{path})->slurp,
      'content of file1',
    );
    is(
      $main::count,
      0,
      'not cached'
    );
  };

  subtest 'first file2' => sub {

    $main::count = 0;

    my $res = $fetch->('http://foo.test/file2.txt');
    is(
      $res,
      hash {
        field type     => 'file';
        field filename => 'file2.txt';
        field path     => T();
      },
      'expected file',
    );
    is(
      $main::count,
      1,
      'not cached'
    );
  };

  subtest 'second file1' => sub {

    $main::count = 0;

    my $res = $fetch->('http://foo.test/file2.txt');
    is(
      $res,
      hash {
        field type     => 'file';
        field filename => 'file2.txt';
        field path     => T();
      },
      'expected file',
    );
    is(
      path($res->{path})->slurp,
      'content of file2',
    );
    is(
      $main::count,
      0,
      'not cached'
    );
  };
  
};

done_testing;

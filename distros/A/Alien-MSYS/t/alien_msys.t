use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Path::Tiny ();
use File::chdir;

$Alien::MSYS::VERSION ||= '0.10';

subtest 'basic' => sub {

  my $build = alienfile_ok q{

    use alienfile;
    use Path::Tiny qw( path );

    # This is where I got config.guess
    # http://www.gnu.org/software/gettext/manual/html_node/config_002eguess.html
    # wget -O config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
    my $config_guess = path('corpus/config.guess')->absolute;

    probe sub { 'share' };

    share {

      plugin 'Build::MSYS';

      download sub { path('file1')->touch };
      extract  sub { path('file2')->touch };
      build    [
        ($^O eq 'MSWin32' ? ('path') : ()),
        'touch file3',
        'mv file3 %{.install.stage}/file3',
        [ 'sh', $config_guess, \'%{.runtime.config_guess}' ],
      ];

    };

  };

  my $alien = alien_build_ok;

  if($alien)
  {
    my $share = $alien->runtime_prop->{prefix};
    is(-f "$share/file3", T(), "installed file3");

    is($alien->runtime_prop->{config_guess}, T(), 'got config.guess value');
    note "config.guess = @{[ $alien->runtime_prop->{config_guess} ]}";
  }
  elsif($^O eq 'MSWin32')
  {
    diag '';
    diag '';
    diag '';
    my $bin_dir = Alien::MSYS::msys_path() || 'undefined';
    diag "bin_dir  = $bin_dir";
    my $dist_dir = Path::Tiny->new(Alien::MSYS->dist_dir)->canonpath;
    diag "dist_dir = $dist_dir";
    diag '';
    diag '';

    if(-d $dist_dir)
    {
      local $CWD = $dist_dir;
      diag "cd $CWD";
      diag '+dir /s';
      diag `dir /s`;
    }
    else
    {
      diag "!!! NO $dist_dir !!!";
    }

    if(-d $bin_dir)
    {
      local $CWD = $bin_dir;
      diag "cd $CWD";
      diag '+dir /s';
      diag `dir /s`;
    }
    else
    {
      diag "!!! NO $bin_dir !!!";
    }

    Alien::MSYS::msys(sub {
      diag "REM Alien::MSYS::msys( ... )";
      diag '+path';
      diag `path`;
    });

    diag '';
    diag '';
  }

};

done_testing;

use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Probe::OverrideCI;
use File::chdir;
use Path::Tiny qw( path );
use File::Temp qw( tempdir );

@INC = map { path($_)->absolute->canonpath } @INC;

delete $ENV{$_} for qw( TRAVIS TRAVIS_BUILD_ROOT APPVEYOR APPVEYOR_BUILD_FOLDER );

my $root = path(tempdir ( CLEANUP => 1 ));

my $dir1 = $root->child("home/travis/build/myusername/Alien-foo");
$dir1->mkpath;
my $dir2 = $root->child("home/travis/.cpanm/work/1504452397.18526/Alien-foo-1.00/Alien-foo-1.00");
$dir2->mkpath;

my %CI = (
  travis => {
    TRAVIS                => 'true',
    TRAVIS_BUILD_DIR      => $dir1->canonpath, 
  },
  appveyor => {
    APPVEYOR              => 'True',
    APPVEYOR_BUILD_FOLDER => $dir1->canonpath,
  },
);

foreach my $ci (sort keys %CI)
{
  subtest $ci => sub {
  
    local %ENV = %ENV;
    foreach my $key (sort keys %{ $CI{$ci} })
    {
      my $value = $CI{$ci}->{$key};
      note "$key=$value";
      $ENV{$key} = $value;
    }
    $ENV{ALIEN_BUILD_PRELOAD} = 'Probe::OverrideCI';
  
    subtest 'in build root' => sub {
    
      local $CWD = $dir1->stringify;

      subtest 'system' => sub {

        local $ENV{ALIEN_INSTALL_TYPE} = 'share';
        local $ENV{ALIEN_INSTALL_TYPE_CI} = 'system';
      
        alienfile_ok q{
          use alienfile;
          probe sub { 'system' };
        };
        
        alien_install_type_is 'system';
      
      };
      
      subtest 'share' => sub {

        local $ENV{ALIEN_INSTALL_TYPE_CI} = 'share';

        alienfile_ok q{
          use alienfile;
          probe sub { 'system' };
        };

        alien_install_type_is 'share';

      };
      
    };  
    
    subtest 'out of build root' => sub {
    
      local $CWD = $dir2;
      
      subtest 'system' => sub {
      
        local $ENV{ALIEN_INSTALL_TYPE_CI} = 'system';
        
        alienfile_ok q{
          use alienfile;
          probe sub { 'share' };
        };
        
        alien_install_type_is 'share';
      
      };
      
      subtest 'share' => sub {
      
        local $ENV{ALIEN_INSTALL_TYPE_CI} = 'share';
        
        alienfile_ok q{
          use alienfile;
          probe sub { 'system' };
        };
        
        alien_install_type_is 'system';
      
      };
    
    };
  
  };
}

done_testing;

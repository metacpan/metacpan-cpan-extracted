use Test2::V0 -no_srand => 1, -no_utf8 => 1;
use Test2::Mock;
use Test::Alien::Build;
use Test::Exit;
use ExtUtils::MakeMaker;
use Alien::Build::Plugin::Fetch::Prompt;
use Capture::Tiny qw( capture_merged );

$ENV{ALIEN_BUILD_PRELOAD} = 'Fetch::Prompt';
delete $ENV{ALIEN_DOWNLOAD};

my $build = alienfile_ok q{
  use alienfile;

  meta->prop->{plugin_download_negotiate_default_url} = "http://alienfile.org/foo/bar/baz";

  share {
  
    fetch sub {
      my($build, $url) = @_;
      
      return {
        type    => 'html',
        charset => 'utf-8',
        base    => $url,
        content => '<html/>',
      };
    };
  
  };  
};

my $mock = Test2::Mock->new(
  class => 'ExtUtils::MakeMaker',
);

subtest 'user says yes' => sub {

  my($msg, $def);

  $mock->override(prompt => sub ($;$) { ($msg,$def) = @_; return 'y' });

  subtest 'default url' => sub {
  
    never_exits_ok {
      $build->fetch;
    };
    
    like $msg, qr{http://alienfile.org/foo/bar/baz};
    note "msg = $msg";
    
    is $def, 'yes';
  
  };
  
  subtest 'non-default url' => sub {
  
    never_exits_ok {
      $build->fetch('http://alienfile.org/bar/baz/foo');
    };
    
    link $msg, qr{http://alienfile.org/bar/baz/foo};
    note "msg = $msg";
    
    is $def, 'yes';
  
  };
  
  subtest 'different default answer' => sub {

    local $ENV{ALIEN_DOWNLOAD} = 'no';
  
    never_exits_ok {
      $build->fetch('http://alienfile.org/bar/baz/foo');
    };
    
    is $def, 'no';
  
  };

};

subtest 'user says no' => sub {

  $mock->override(prompt => sub ($;$) { 'n' });
  
  is exit_code { capture_merged { $build->fetch } }, 2;

};

done_testing;

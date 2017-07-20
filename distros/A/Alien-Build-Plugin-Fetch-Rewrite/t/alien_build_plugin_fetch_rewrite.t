use Test2::V0 -no_srand => 1;
use Test2::Mock;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::Rewrite;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

$ENV{ALIEN_BUILD_POSTLOAD} = 'Fetch::Rewrite';

my $build = alienfile_ok q{
  use alienfile;

  log 'setting start_url';
  meta->prop->{start_url} = 'bogus://bogus1';
  
  probe sub { 'share' };
  
  share {
  
    fetch sub { die 'oh noes!' }
  
  };
};

$build->load_requires($build->install_type);

subtest 'failure' => sub {

  eval { $build->fetch };
  my $error = $@;

  isnt $error, '';  
  note "error = $error";

};

sub res2content
{
  my($res) = @_;
  $res->{content} ? $res->{content} : path($res->{path})->slurp_raw;
}

subtest 'basic good' => sub {

  my $orig;
  my $exp = path('corpus/dist/foo-1.00.tar')->absolute;

  my $mock = Test2::Mock->new(class => 'Alien::Build::rc');
  $mock->add(rewrite => sub {
    my($build, $url) = @_;
    $orig = $url->clone;
    $url->scheme('file');
    $url->host('localhost');
    $url->path($exp);
  });
  
  subtest 'with start_url' => sub {

    my $ret; eval {
    note scalar capture_merged {
        $ret = $build->fetch
      };
    };
    
    is $@, '';
  
    is(
      $orig,
      object {
        call ['isa', 'URI'] => T();
        call scheme => 'bogus';
      },
    );

    is $ret->{filename}, 'foo-1.00.tar';
    is res2content($ret), $exp->slurp_raw;

  };
  
  subtest 'with another url' => sub{
  
    my $ret;
    note scalar capture_merged {
      $ret = $build->fetch('http://bogus1/bogus2');
    };
    
    is $@, '';
  
    is(
      $orig,
      object {
        call ['isa', 'URI'] => T();
        call scheme => 'http';
        call host   => 'bogus1';
        call path   => '/bogus2';
      },
    );
  
    is $ret->{filename}, 'foo-1.00.tar';
    is res2content($ret), $exp->slurp_raw;

  };

};

done_testing

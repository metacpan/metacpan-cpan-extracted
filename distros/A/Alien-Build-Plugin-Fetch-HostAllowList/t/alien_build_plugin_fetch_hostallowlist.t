use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use URI;

delete $ENV{ALIEN_BUILD_HOST_ALLOW};

alien_subtest 'basic' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };
    share {
      start_url 'https://foo.com/foo.txt';
      plugin 'Fetch::HostAllowList', allow_hosts => ['foo.com','bar.com'];
      fetch sub {
        my(undef, $url) = @_;
        $url = 'https://foo.com/foo.txt' unless defined $url;
        $url = URI->new("$url");
        return {
          type     => 'file',
          filename => 'foo.txt',
          content  => '',
          protocol => $url->scheme,
        };
      };
    };
  };

  alienfile_skip_if_missing_prereqs;
  alien_install_type_is 'share';

  try_ok {
    $build->fetch;
  } 'works with start url';

  try_ok {
    $build->fetch('https://bar.com/foo.txt');
  } 'works with explicit url';

  is dies {
    $build->fetch('https://baz.com/foo.txt');
  }, match qr/^The host baz.com is not in the allow list/, 'fails with a unallowed host';

};

done_testing;



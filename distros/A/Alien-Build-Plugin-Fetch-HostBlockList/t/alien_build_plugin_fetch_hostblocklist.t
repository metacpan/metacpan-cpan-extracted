use Test2::V0 -no_srand => 1;
use Test::Alien::Build;

delete $ENV{ALIEN_BUILD_HOST_BLOCK};

alien_subtest 'basic' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };
    share {
      start_url 'https://foo.com/foo.txt';
      plugin 'Fetch::HostBlockList', block_hosts => ['foo.com','bar.com'];
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

  is dies {
    $build->fetch;
  }, match qr/^The host foo.com is in the block list/, 'fails with start url';

  try_ok {
    $build->fetch("https://google.com");
  } 'works with non-blocked host';

  is dies {
    $build->fetch('https://bar.com/foo.txt');
  }, match qr/^The host bar.com is in the block list/, 'fails with explicitly blocked URL';

};

done_testing;

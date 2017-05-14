use Test::More;
use Test::Exception;
use Test::TinyMocker;

use Acme::CatFS;

subtest "basic" => sub {
  can_ok 'Acme::CatFS', 'run', 'new', 'new_with_options';

  my $catfs = Acme::CatFS->new(mountpoint => '/');

  isa_ok $catfs, 'Acme::CatFS';
};

subtest "mountpoint should be required" => sub {
  throws_ok {
    Acme::CatFS->new
  }
  qr/mountpoint/,
  'mountpoint should be required';
};

subtest "run should call Fuse::Simple::main and LWP::Simple::get" => sub {
  my $random_cat_pic;

  mock 'LWP::Simple'
    => method 'get'
    => should {
      $random_cat_pic = shift;

      'random'
    };

  mock 'Fuse::Simple'
    => method 'main'
    => should {
      my (%params) = @_;

      ok ! $params{debug}, 'debug should be false';
      is $params{mountpoint}, '/', 'mountpoint should be /';
      is ref($params{'/'}->{'cat.jpg'}), 'CODE', 'cat.jpg should be a CODEREF';
      is $params{'/'}->{'cat.jpg'}->(), 'random', 'CODEREF should call LWP::Simple::get';
    };

   my $catfs = Acme::CatFS->new(mountpoint => '/');

   $catfs->run;

   is $random_cat_pic, $catfs->cat_url, 'should call LWP::Simple::get with cat_url';
};

done_testing();
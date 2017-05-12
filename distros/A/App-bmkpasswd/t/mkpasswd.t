use Test::More;
use strict; use warnings;

use App::bmkpasswd -all;

subtest bcrypt => sub {
  my $bc;
  ok $bc = mkpasswd('snacks'), 'bcrypt crypt()';
  ok index($bc, '$2a$') == 0, 'looks like bcrypt';
  ok passwdcmp('snacks', $bc), 'bcrypt compare';
  ok !passwdcmp('things', $bc), 'bcrypt negative compare';

  $bc = undef;
  ok $bc = mkpasswd('snacks', 'bcrypt', 2), 'bcrypt tuned workcost';
  ok index($bc, '$2a$02') == 0, 'bcrypt tuned workcost looks ok';
  ok passwdcmp('snacks', $bc), 'bcrypt tuned workcost compare';
  ok ! passwdcmp('things', $bc), 'bcrypt tuned negative compare';
  ok ! defined passwdcmp('things', $bc), 'failed passwdcmp returns undef';

  # more hash-style opt passing tests in saltgen subtest, below
  $bc = mkpasswd foo => +{ cost => 6 };
  ok index($bc, '$2a$06') == 0, 'bcrypt hash-style opts generation';
  ok passwdcmp('foo', $bc), 'bcrypt hash-style opts comparison';
};

subtest md5 => sub {
  plan skip_all => "No MD5 support; install Crypt::Passwd::XS"
    unless mkpasswd_available('md5');

  my $md5;
  ok $md5 = mkpasswd('snacks', 'md5'), 'MD5 crypt()';
  ok index($md5, '$1$') == 0, 'looks like MD5';
  ok passwdcmp('snacks', $md5), 'MD5 compare';
  ok !passwdcmp('things', $md5), 'MD5 negative compare';
};

subtest sha256 => sub {
  plan skip_all => "No SHA256 support; install Crypt::Passwd::XS"
    unless mkpasswd_available('sha256');

  diag App::bmkpasswd::have_passwd_xs() ? "Using Crypt::Passwd::XS for SHA"
    : "Using system crypt() for SHA";

  my $sha;
  ok $sha = mkpasswd('snacks', 'sha256'), 'SHA256 crypt()';
  ok index($sha, '$5$') == 0, 'looks like SHA256';
  ok passwdcmp('snacks', $sha), 'SHA256 compare';
  ok !passwdcmp('things', $sha), 'SHA256 negative compare';

  ok $sha = mkpasswd('snacks', 'SHA-256'), 'SHA-256 crypt()';
  ok index($sha, '$5$') == 0, 'looks like SHA256 ("SHA-256")';
};

subtest sha512 => sub {
  plan skip_all => "No SHA512 support; install Crypt::Passwd::XS"
    unless mkpasswd_available('sha512');

  my $sha512;
  ok $sha512 = mkpasswd('snacks', 'sha512'), 'SHA512 crypt()';
  ok index($sha512, '$6$') == 0, 'looks like SHA512';
  ok passwdcmp('snacks', $sha512), 'SHA512 compare';
  ok !passwdcmp('things', $sha512), 'SHA512 negative compare';

  ok $sha512 = mkpasswd('snacks', 'SHA-512'), 'SHA-512 crypt()';
  ok index($sha512, '$6$') == 0, 'looks like SHA512 ("SHA-512")';
};

subtest mkpasswd_available => sub {
  ok mkpasswd_available('bcrypt'), 'mkpasswd_available';
  ok !mkpasswd_available('foo'), 'negative mkpasswd_available';
};

subtest mkpasswd_forked => sub {
  my $orig_brs = App::bmkpasswd::get_brs;
  ok $orig_brs == App::bmkpasswd::get_brs, 'get_brs ok';
  mkpasswd_forked;
  my $bc = mkpasswd('snacks');
  ok index($bc, '$2a$') == 0, 'bcrypt after mkpasswd_forked ok';
  my $new_brs = App::bmkpasswd::get_brs;
  ok $orig_brs != $new_brs, 'mkpasswd_forked reset Bytes::Random::Secure';
};

subtest saltgen => sub {
  plan skip_all => "No SHA support"
    unless mkpasswd_available('sha256');

  my $sha = mkpasswd( snacks => +{
    type    => 'sha256',
    strong  => 1,
    saltgen => sub {
      my ($type, $strong) = @_;
      ok $strong, 'strong salt opt passed ok';
      ok $type eq 'sha', 'saltgen got correct type';
      return 'ababcdcd'
    },
  });
  ok index($sha, '$5$ababcdcd$') == 0, 'sha with saltgen looks ok';
  ok passwdcmp('snacks', $sha), 'sha with saltgen compares ok';
};

done_testing

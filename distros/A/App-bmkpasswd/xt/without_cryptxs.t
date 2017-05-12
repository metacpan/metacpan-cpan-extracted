use Test::More;
use strict; use warnings FATAL => 'all';

use App::bmkpasswd -all;

BEGIN {
  unless (eval { require Test::Without::Module; 1 } && !$@) {
    Test::More::plan(skip_all =>
      'these tests require Test::Without::Module'
    );
  }
}

use Test::Without::Module 'Crypt::Passwd::XS';

App::bmkpasswd::have_passwd_xs and die "Crypt::Passwd::XS still loaded!";

my $sha;
ok( $sha = mkpasswd('snacks', 'sha256'), 'SHA256 crypt()' );
ok( index($sha, '$5$') == 0, 'Looks like SHA256' );
ok( passwdcmp('snacks', $sha), 'SHA256 compare' );
ok( !passwdcmp('things', $sha), 'SHA256 negative compare' );

my $sha512;
ok( $sha512 = mkpasswd('snacks', 'sha512'), 'SHA512 crypt()' );
ok( index($sha512, '$6$') == 0, 'Looks like SHA512' );
ok( passwdcmp('snacks', $sha512), 'SHA512 compare' );
ok( !passwdcmp('things', $sha512), 'SHA512 negative compare' );


done_testing;

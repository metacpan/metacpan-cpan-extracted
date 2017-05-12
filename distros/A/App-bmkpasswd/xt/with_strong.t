use Test::More;
use strict; use warnings;

diag "This test will require available entropy!";

use App::bmkpasswd -all;

SKIP: {
  unless ( mkpasswd_available('sha256') ) {
    diag 
      "No SHA support found\n",
      "You may want to install Crypt::Passwd::XS"
    ;
    skip "No SHA support", 8;
  } else {
    diag "Found SHA support";
  }
  
  if ( App::bmkpasswd::have_passwd_xs() ) {
    diag "Using Crypt::Passwd::XS for SHA" ;
  } else {
    diag "Using system crypt() for SHA";
  }

  my $sha;
  ok $sha = mkpasswd('snacks', 'sha256', '', 1), 'SHA256 crypt() (strong)';
  ok index($sha, '$5$') == 0, 'Looks like SHA256';
  ok passwdcmp('snacks', $sha), 'SHA256 compare';  
  ok !passwdcmp('things', $sha), 'SHA256 negative compare';
}

done_testing

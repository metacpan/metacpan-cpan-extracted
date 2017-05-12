# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

###################################################################
use Test::More qw(no_plan);

use Data::Password qw(IsBadPassword $MAXLEN @DICTIONARIES $SKIPCHAR $BADCHARS);

ok(1,'Module Loaded');

{
      my $pass = "\0BC2f4a";
      my $reason = IsBadPassword($pass) || '';
      ok($reason ,"$pass: $reason");
      $SKIPCHAR = 1;
      my $reason = IsBadPassword($pass) || '';
      ok(! $reason ,"$pass: $reason");
      $SKIPCHAR = 0;
}

{
      $SKIPCHAR = 0;
      my $pass = "0BC2f4a";
      my $reason = IsBadPassword($pass) || '';
      ok(! $reason ,"$pass: $reason");
      $BADCHARS = '^A-Z1-9';
      $reason = IsBadPassword($pass) || '';
      ok($reason ,"$pass: $reason");
      $pass = "BCAFDQ11";
      $reason = IsBadPassword($pass) || '';
      ok(! $reason ,"$pass: $reason");
}

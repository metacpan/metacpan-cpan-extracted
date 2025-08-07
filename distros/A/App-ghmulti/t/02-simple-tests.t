#!perl
use 5.010;
use strict;
use warnings;
use Test::More tests => 2;

use Capture::Tiny ':all';

use File::Spec::Functions;

use File::Basename;


BEGIN {
    use_ok( 'App::ghmulti' ) || BAIL_OUT("Could not load module 'App::ghmulti'");
}


{
  my $argv_str = '-u https://github.com/user1/repo1.git';
  local @ARGV = split(/\s+/, $argv_str);
  like(capture_stdout { App::ghmulti::run() },
       qr!^git\@github-user1:user1/repo1\.git\s*$!,
       "test args: $argv_str");
}

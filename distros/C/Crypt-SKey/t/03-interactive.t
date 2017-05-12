use Test;

BEGIN {
  require "t/common.pl";
  skip_test("We don't seem to have a terminal for interactive mode")
    unless -t STDIN;
  
  $Crypt::SKey::HASH = (have_module('Digest::MD4') ? 'MD4' :
			have_module('Digest::MD5') ? 'MD5' :
			skip_test("Neither of Digest::MD4, Digest::MD5 is installed"));
  
  need_module('Term::ReadKey');
}

BEGIN { plan tests => 2 }

use strict;
use Crypt::SKey qw(key compute);
ok(1);

{
  warn "\nTesting interactive mode: enter 'pwd' (without quotes) at the prompt:\n";
  local @ARGV = (50, 'fo099804');
  my $got = key;
  my $expect = 'HESS SWIM RAYS DING MOAT FAWN';
  ok($got, $expect, $got);
}


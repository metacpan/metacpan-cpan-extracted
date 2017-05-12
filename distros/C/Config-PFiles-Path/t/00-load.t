#!perl

use Test::More tests => 1;

BEGIN {
  use_ok('Config::PFiles::Path');
}

diag( "Testing Config::PFiles::Path $Config::PFiles::Path::VERSION, Perl $], $^X" );

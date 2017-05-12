use Test::More tests => 2;

BEGIN {
  use_ok( 'App::PerlPPP' );
  use_ok( 'Crypt::PerfectPaperPasswords' );
}

diag("Testing Crypt::PerfectPaperPasswords"
   . " $Crypt::PerfectPaperPasswords::VERSION" );

#!./perl

use Test::More tests => 2 + ($^W = 0);

eval "\nuse Classic'Perl jmjbatabjm";
like
   $@,
   qr"^jmjbatabjm\ is\ not\ a\ feature\ Classic::Perl\ knows\ about\ at\ 
      \(eval\ [0-9]+\)\ line\ [0-9]+.\n"x
;

eval "\nno Classic'Perl otodihohid";
like
   $@,
   qr"^otodihohid\ is\ not\ a\ feature\ Classic::Perl\ knows\ about\ at\ 
      \(eval\ [0-9]+\)\ line\ [0-9].\n"x
;

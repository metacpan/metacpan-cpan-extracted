#-*- mode: perl;-*-

use strict;
use warnings;

use Test::More tests => 4;

use_ok("Acme::Innuendo");

sub some_subroutine_name { return 1; }

ok( wink_wink( special_place(), "some_subroutine_name") );

nudge_nudge( special_place(), "alias_of_some_sub",
 wink_wink( special_place(), "some_subroutine_name") );

ok( wink_wink( special_place(), "alias_of_some_sub") );
{
  no strict;
  ok(alias_of_some_sub());
}

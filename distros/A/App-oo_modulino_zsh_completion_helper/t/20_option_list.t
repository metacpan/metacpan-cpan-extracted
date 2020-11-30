#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

my $cmdFn = "$FindBin::Bin/../script/oo_modulino_zsh_completion_helper.pl";

{

  my $testFn = "$FindBin::Bin/../samples/2-options/lib/Greetings_oo_modulino_with_fields.pm";

  is(scalar qx($^X $cmdFn zsh_options pmfile $testFn)
     , <<END, "All options (== fields)");
--name=-
--no-thanx=-
--x=-
--y=-
END

  is(scalar qx($^X $cmdFn zsh_options pmfile $testFn CURRENT 1 words '["--"]')
     , <<END, "Option leader(--) is ignored");
--name=-
--no-thanx=-
--x=-
--y=-
END

  is(scalar qx($^X $cmdFn zsh_options pmfile $testFn CURRENT 1 words '["--n"]')
     , <<END, "Options which match given prefix");
--name=-
--no-thanx=-
END

}

{

  my $testFn = "$FindBin::Bin/../samples/2-options/lib/Derived.pm";

  is(scalar qx($^X $cmdFn zsh_options pmfile $testFn)
     , <<END, "All options (== fields) including inherited ones");
--height=-
--name=-
--no-thanx=-
--width=-
--x=-
--y=-
END

}

done_testing();

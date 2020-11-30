#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

my $cmdFn = "$FindBin::Bin/../script/oo_modulino_zsh_completion_helper.pl";

{

  my $testFn = "$FindBin::Bin/../samples/3-mop4import-declare/Greetings_CLI_JSON.pm";

  is(scalar qx($^X $cmdFn zsh_methods pmfile $testFn)
     , <<END, "All methods with :Doc()");
hello:Say hello to someone
hi:Say Hi to someone
END

  is(scalar qx($^X $cmdFn zsh_options pmfile $testFn)
     , <<END, "All options with doc");
--name=-[Name of someone to be greeted]
--no-thanx=-
--x=-
--y=-
END

}

done_testing();

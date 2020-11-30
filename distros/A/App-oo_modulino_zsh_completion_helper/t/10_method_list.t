#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

my $cmdFn = "$FindBin::Bin/../script/oo_modulino_zsh_completion_helper.pl";

{

  my $testFn = "$FindBin::Bin/../samples/1-methods/lib/Greetings.pm";

  is(scalar qx($^X $cmdFn zsh_methods pmfile $testFn)
     , <<END, "All methods");
hello
hi
END

  is(scalar qx($^X $cmdFn zsh_methods pmfile $testFn CURRENT 1 words '["he"]')
     , <<END, "Methods which match given prefix");
hello
END

}

{

  my $testFn = "$FindBin::Bin/../samples/1-methods/lib/Derived.pm";

  is(scalar qx($^X $cmdFn zsh_methods pmfile $testFn)
     , <<END, "All methods except inherited ones");
good_afternoon
good_evening
good_morning
END

  is(scalar qx($^X $cmdFn zsh_methods pmfile $testFn NUMERIC 1)
     , <<END, "All methods including inherited ones");
good_afternoon
good_evening
good_morning
hello
hi
END

}

done_testing();

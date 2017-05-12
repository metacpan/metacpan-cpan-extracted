
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 12;
use strict;
use warnings;
 
# the module we need
use Data::Reuse qw(fixate forget);

fixate my @array1 => qw(foo bar baz);
fixate my @array2 => qw(foo bar baz);
is \$array1[$_], \$array2[$_] foreach 0 .. $#array1;

forget();
is \$array1[$_], \$array2[$_] foreach 0 .. $#array2;

fixate my @array3 => qw(foo bar baz);
isnt \$array3[$_], \$array2[$_] foreach 0 .. $#array3;

fixate my @array4 => qw(foo bar baz);
is \$array3[$_], \$array4[$_] foreach 0 .. $#array4;

use warnings;
use strict;

use Test::More;

plan tests => 7;

use Code::ART;

my $CODE = q{
    $postincr++;
    --$predecr;
    $asgn = $not_aref_sval;
    $asgn = $not_aref + $listlval1_sref;
    ($listlval1, $listlval2) = ($not_aref, $listlval1_sref);
};

my ($postincr, $predecr, $asgn, $not_aref, $not_aref_sval, $listlval1_sref, $listlval1, $listlval2)
 = (1,         2,        3,     4,         5,              6,               7,          8);

eval "$CODE";

is $postincr       , 2  => 'postincrement okay';
is $predecr        , 1  => 'predecrement okay';
is $asgn           , 10 => 'assignment okay';
is $not_aref       , 4  => 'm unchanged';
is $listlval1_sref , 6  => 'n unchanged';
is $listlval1      , 4  => 'list assignment 0 okay';
is $listlval2      , 6  => 'list assignment 1 okay';

done_testing();




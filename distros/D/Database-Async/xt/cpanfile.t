use strict;
use warnings;
use Test::CPANfile;
use Test::More;
 
TODO: {
    local $TODO = 'does not support Perl version in Makefile.PL or cpanfile';
    cpanfile_has_all_used_modules(
        suggests     => 1,
        recommends   => 1,
    );
};
done_testing;

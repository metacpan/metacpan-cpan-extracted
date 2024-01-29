
use strict;
use warnings;
use Test::More;
use lib 't/lib';

eval { require ErrSig; };
like $@, qr/syntax error.*found 'i'/;

eval { require ErrBodyBlock; };
like $@, qr/syntax error.*start of block/;

eval { require ErrBodySyntax; };
like $@, qr/Bareword "nope" not allowed/;

done_testing;



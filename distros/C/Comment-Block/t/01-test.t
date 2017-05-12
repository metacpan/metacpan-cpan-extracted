use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Comment::Block;
use Test::Block;
use Test::More;

{
    package Test::Block2;

    sub test {
        #/*
            return 0;
        #*/
            return 1;
    }
}

#/*
    ok(0, "Comment was called when it shouldn't of been"); 
#*/

ok(1, "Code outside of comment runs find");

ok(Test::Block::test(), "Namespaces clean");
ok(Test::Block2::test(), "Namespace in multi file Packages not clean");

done_testing;

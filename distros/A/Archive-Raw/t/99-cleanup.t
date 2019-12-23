#!perl

use Test::More;
use File::Path qw/remove_tree/;

remove_tree ('t/testextract');
ok !-e 't/testextract';

done_testing();


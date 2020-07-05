#!perl

use File::Path qw/remove_tree/;
use Test::More;

remove_tree ('t/testextract_tar');
remove_tree ('t/testextract_zip_encrypted');
ok !-e 't/testextract_tar';
ok !-e 't/testextract_zip_encrypted';

done_testing();


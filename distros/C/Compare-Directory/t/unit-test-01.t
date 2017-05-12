#!perl

use Test::More tests => 4;

BEGIN { use_ok('Compare::Directory'); }

my ($directory, $status);
my ($got_error, $exp_error);

$directory = Compare::Directory->new('t/got-1', 't/exp-1');
$status    = $directory->cmp_directory();
is($status, 1);

eval
{
    $directory = Compare::Directory->new('t/got-2', 't/exp-1');
    $status    = $directory->cmp_directory();
};
$got_error = $@;
chomp($got_error);
like($got_error, '/ERROR: Invalid directory/');    

eval
{
    $directory = Compare::Directory->new('t/got-1', 't/exp-2');
    $status    = $directory->cmp_directory();
};
$got_error = $@;
chomp($got_error);
like($got_error, '/ERROR: Invalid directory/');    

done_testing();
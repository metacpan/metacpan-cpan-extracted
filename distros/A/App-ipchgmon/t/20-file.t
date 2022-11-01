use strict;
use warnings;
use Test::More;
use Test::File;
use FindBin qw( $RealBin );

my $NAME = 'ipchgmon';
my $invoke = "$^X $RealBin/../bin/$NAME";

# Integration test to ensure a file is created when ipchgmon
# is used from the command line.

# If the directory is not writable, the tests cannot pass,
# so ignore them
plan skip_all => 'Unable to write files' unless -w $RealBin;

my $fqname = $RealBin . '/test.txt';
file_not_exists_ok($fqname, 'File should not exist yet');

my $rtn = qx($invoke --file $fqname --server example.com 2>&1);
file_exists_ok($fqname, 'File should be created if it doesn\'t exist ...');
file_not_empty_ok($fqname, '... and should contain something.');

unlink $fqname or warn "Unable to delete $fqname at end of tests.";

done_testing;

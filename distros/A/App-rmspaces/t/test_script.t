use strict;
use warnings;
use Test::Script;
use Test::More tests => 10;
use File::Copy qw(move);
 
my %options = ();

script_compiles('script/rmspaces');

script_runs(['script/rmspaces', 't/data/no_space'], 'Test clean run');

$options{'exit'} = 1;
script_runs(['script/rmspaces', '--help'], \%options, 'help option exist status is 1');

# Check default usage
script_runs(['script/rmspaces', 't/data/has space'], 'removing space from file');
ok(-e 't/data/has_space', 'new file without spaces exists');
ok(! -e 't/data/has space', 'old file with spaces does not exist');
move 't/data/has_space', 't/data/has space';

# Check usage with different separator
script_runs(['script/rmspaces', '-s', '-', 't/data/has space'], 'replace space with -');
ok(-e 't/data/has-space', 'new file with - exists');
move 't/data/has-space', 't/data/has space';

# Check usage with different separator and target
script_runs(['script/rmspaces', '-t', '_', '-s', '-', 't/data/no_space'], 'replace _ with -');
ok(-e 't/data/no-space', 'new file with no _ exists');
move 't/data/no-space', 't/data/no_space';

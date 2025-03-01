use strict;
use warnings;
use 5.010_001;
use Test::Compile;

my @scripts = (
    'examples/01.pl',
    'examples/02.pl',
    'examples/03.pl',
    'examples/04.pl',
    'examples/05.pl',
);

for my $test (Test::Compile->new()) {
    $test->all_files_ok();
    for my $file (@scripts) {
        if ($test->pl_file_compiles($file)) {
            $test->ok(1, "$file compiles");
        }
        else {
            $test->ok(0, "$file does not compile");
        }
    }
    $test->done_testing();
}

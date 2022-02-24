#!perl

use strict;
use warnings;

use Test::More import => [qw( done_testing subtest )];
use Test::Script qw(
    script_compiles
    script_fails
    script_runs
    script_stderr_like
);

script_compiles('script/perlvars');

subtest 'file not found' => sub {
    script_fails( [ 'script/perlvars', 'Moose' ], { exit => 1 } );
    script_stderr_like(qr{Moose could not be found});
};

subtest 'file has errors' => sub {
    script_fails(
        [ 'script/perlvars', 'test-data/lib/Local/Unused.pm' ],
        { exit => 255 },
    );
    script_stderr_like(qr{\$unused});
    script_stderr_like(qr{\$one});
    script_stderr_like(qr{\$two});
    script_stderr_like(qr{\$three});
};

subtest 'file has no package' => sub {
    script_runs(
        [ 'script/perlvars', 't/perlvars.t' ],
    );
};

subtest 'arg is a dir' => sub {
    script_fails(
        [ 'script/perlvars', 't' ],
        { exit => 1 },
    );
    script_stderr_like(qr{t is a dir});
};

subtest 'ignore file is used' => sub {
    script_runs(
        [
            'script/perlvars',
            '--ignore-file', 'test-data/ignore-file',
            'test-data/lib/Local/Unused.pm'
        ]
    );
};

subtest 'file has no errors' => sub {
    script_runs(
        [ 'script/perlvars', 'test-data/lib/Local/NoUnused.pm' ],
    );
};

subtest 'multiple files are checked' => sub {
    script_runs(
        [
            'script/perlvars',
            '--ignore-file', 'test-data/ignore-file',
            'test-data/lib/Local/Unused.pm',
            'test-data/lib/Local/NoUnused.pm',
        ]
    );
};

done_testing();

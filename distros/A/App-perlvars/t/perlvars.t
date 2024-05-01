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

# For perl version 5.37.3 there was a change in the Perl internals such that
# some variables are no longer considered unused by Test::Vars. This is a known issue, see
# https://github.com/houseabsolute/p5-Test-Vars/issues/47
# Until this is resolved, we need to adjust the expected number of errors depending on
# the Perl version.
my $perl_old = $] <= 5.037002;

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
    script_runs( [ 'script/perlvars', 't/perlvars.t' ] );
};

subtest 'arg is a dir' => sub {
    script_fails( [ 'script/perlvars', 't' ], { exit => 1 }, );
    script_stderr_like(qr{t is a dir});
};

subtest 'ignore file is used' => sub {
    my @script = (
        'script/perlvars',       '--ignore-file',
        'test-data/ignore-file', 'test-data/lib/Local/Unused.pm',
    );
    if ($perl_old) {
        script_runs( \@script );
    }
    else {
        script_fails( \@script, { exit => 255 } );
    }
};

subtest 'file has no errors' => sub {
    my @script = ( 'script/perlvars', 'test-data/lib/Local/NoUnused.pm', );
    if ($perl_old) {
        script_runs( \@script );
    }
    else {
        script_fails( \@script, { exit => 255 } );
    }
};

subtest 'multiple files are checked' => sub {
    my @script = (
        'script/perlvars',       '--ignore-file',
        'test-data/ignore-file', 'test-data/lib/Local/Unused.pm',
        'test-data/lib/Local/NoUnused.pm',
    );
    if ($perl_old) {
        script_runs( \@script );
    }
    else {
        script_fails( \@script, { exit => 255 } );
    }
};

done_testing();

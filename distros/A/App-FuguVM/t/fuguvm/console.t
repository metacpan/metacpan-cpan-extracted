#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The argument contract of the shipped expect scripts. The scripts
# read their arguments by position, so the order here is the order
# that each script documents.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use Fugu::TestLog;

use_ok('App::FuguVM::Console');

# run_install passes the root password, the proxy URL, the
# architecture and the verify word, in that order, after the host and
# the port that _expect adds.
{
    my $console = App::FuguVM::Console->new(host => '127.0.0.1', port => 4444);

    my @seen;
    {
	no warnings 'redefine';
	local *App::FuguVM::Console::_expect = sub ($self, $script, @args) {
	    @seen = ($script, @args);
	    return 1;
	};
	ok($console->run_install({
	    root_password => 'secret',
	    proxy_url     => 'http://10.0.2.2:8080',
	    arch          => 'arm64',
	    verify        => 'no',
	}), 'run_install dispatches');
    }

    like($seen[0], qr/install\.exp$/, 'the script is install.exp');
    is_deeply([ @seen[1 .. 4] ],
	['secret', 'http://10.0.2.2:8080', 'arm64', 'no'],
	'the arguments arrive in the documented order');

    {
	no warnings 'redefine';
	local *App::FuguVM::Console::_expect = sub ($self, $script, @args) {
	    @seen = ($script, @args);
	    return 1;
	};
	$console->run_install({ arch => 'arm64' });
    }
    is_deeply([ @seen[1 .. 4] ], ['openbsd', 'none', 'arm64', 'yes'],
	'each absent value reads as its default, verify included');
}

# The verify word is the sixth positional argument of install.exp,
# after the host and the port. A drift between the script and the
# tool would type answers at the wrong prompts.
{
    my $script = App::FuguVM::Console->script_path('install.exp');
    ok(defined $script && -f $script, 'the shipped script resolves');

    open my $fh, '<', $script or die "read $script: $!";
    my $body = do { local $/; <$fh> };
    close $fh;

    like($body, qr/^set verify \[lindex \$argv 5\]$/m,
	'install.exp reads the verify word at position six');
    like($body, qr/llength \$argv\] != 6/,
	'and it requires six arguments');
}

done_testing();

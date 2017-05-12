use strict;
use warnings;

use Test::More tests => 6;
use Class::Load qw( try_load_class );

use FindBin qw( $Bin );
my $command = "$^X $Bin/../bin/plackbench";

SKIP: {
    if ( !try_load_class('Capture::Tiny') ) {
        skip 'Capture::Tiny not installed', 6;
    }

    my ($stdout, $stderr, $exit);

    ($stdout, $stderr, $exit) = run($command);
    like($stdout, qr/Usage/, 'should output a usage message with no args');
    ok($exit, 'should exit unsuccessfully when passed no args');

    ($stdout, $stderr, $exit) = run("$command -n 10 $Bin/test_app.psgi /ok");
    ok(!$exit, 'should exit successfully');
    like($stdout, qr/Request times/, 'should output something reasonable');

    my $e_arg = q[-e'$_->url("/fail")'];
    if ($^O eq 'MSWin32') {
        $e_arg = q[-e"$_->url('/fail')"];
    }

    ($stdout, $stderr, $exit) = run("$command $e_arg $Bin/test_app.psgi /ok");
    ok($exit, 'should use -e flag as a fixup');

    ($stdout, $stderr, $exit) = run("$command -f $Bin/fail_redirect $Bin/test_app.psgi /ok");
    ok($exit, 'should use -f flag as a fixup file path');
}

sub run {
    my $command = shift;
    return Capture::Tiny::capture(sub {
        system($command);
    });
}

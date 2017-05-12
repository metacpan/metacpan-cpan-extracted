use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Capture::Tiny 0.12 qw(capture);
use App::Prove;

use ok "App::Prove::Plugin::SetEnv";


delete $ENV{"APP_PROVE_PLUGIN_SETENV_TEST_$_"}
    foreach qw(FOO BAR);

is exception {
    my ($stdout, $stderr, $result) = capture {
        my $app = App::Prove->new;
        $app->process_args(
            qw(--norc -Q -P),
            'SetEnv=' . join(',', map { "APP_PROVE_PLUGIN_SETENV_TEST_$_=$_" } qw(FOO BAR)),
            't/data/env.pl'
        );
        $app->run;
    };
    ok $result, "success";
    like $stdout, qr/PASS/, "PASS in output";
    is $stderr, "", "no error output";
}, undef, "no exception";

done_testing();

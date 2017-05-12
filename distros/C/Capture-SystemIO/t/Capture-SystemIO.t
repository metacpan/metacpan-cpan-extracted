
use Test::More;
use strict;
use warnings;

BEGIN {
    my $output = `echo -n something`;
    system('kill -INT $$');
    my $sigcheck = ($?&127);

    if($output ne 'something') {
        plan skip_all =>
            "I tried to echo something, but something did not come back.";
    } elsif (8 != (my $exit = (system("(exit 8)")>>8))) {
        plan skip_all =>
            "I tried to exit 8, but 8 it did not, $exit";
    } elsif(!$sigcheck) {
        plan skip_all =>
            "Tell them I signaled, and no one answered,/That I kept my word";
    } else {
        plan tests => 12;
    }
    
}
use Capture::SystemIO qw(cs_system);
use Data::Dumper;
use Exception::Class;
our $ec = 'Exception::Class';

ok(1, 'load_module'); # If we made it this far, we're ok.


{
    my ($stdout, $stderr) = cs_system('echo -n "something"');
    is($$stdout, "something", 'echo something');
}


{
    my ($stdout, $stderr);
    eval {
        ($stdout, $stderr) = cs_system('false');
    }; if (my $e = $ec->caught("Capture::SystemIO::Error")) {
        is($e->return_code(), 256, 'failed command');
    }
}


{
    my ($stdout, $stderr);
    eval {
        ($stdout, $stderr) = cs_system('echo -n "Test" 1>&2');
    }; ok(!$@, 'Run: echo "Test" 1>&2"');

    is($$stderr, "Test", 'stderr: echo "Test" 1>&2"');
}


{
    my ($stdout, $stderr);
    eval {
        ($stdout, $stderr) = cs_system('(echo -n "TestERR" 1>&2); echo -n "TestOUT"');
    };
    ok(!$@, 'Run: (echo -n "TestERR" 1>&2); echo -n "TestOUT"');

    is($$stdout, "TestOUT", 'stderr:TestOUT');
    is($$stderr, "TestERR", 'stderr:TestERR');
}


{
    local($Capture::SystemIO::T) = 1;
    my ($stdout, $stderr) = cs_system('(echo -n "ok TestERR-T" 1>&2); echo -n "ok TestOUT-T"');
    is($$stdout, "ok TestOUT-T", 'stderr:TestOUT-T');
    is($$stderr, "ok TestERR-T", 'stderr:TestERR-T');

};
TODO: {
    local $TODO = "Test Signal Handling" if 1;
    eval {
        my ($stdout, $stderr) = cs_system('kill -INT $$');
    }; if (my $e = $ec->caught("Capture::SystemIO::Interrupt")) {
        is($e->signal(),'Interrupt', 'SIG INT');
    }  else {
        ok(0, "SIG INT");
    }
    eval {
        my ($stdout, $stderr) = cs_system('kill -QUIT  $$');
    }; if (my $e = $ec->caught("Capture::SystemIO::Interrupt")) {
        is($e->signal(),'Quit', 'SIGQUIT');
    } else {
        ok(0, "SIG QUIT");
    }

};








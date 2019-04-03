use strict;
use warnings;
use feature 'say';

use Test::More tests => 3;
use Test::Trap;

use App::Task;

diag("Testing App::Task $App::Task::VERSION");

sub _out;

trap {
    print "I am at depth 0\n";

    task "Foo" => sub {
        _out "newline", "I am foo\nWho are you?\n";

        task "foo nested 1" => sub {
            _out "newline", "Before: I (2) am still foo\nare you still you?\n";

            task "foo nested 2" => sub {
                _out "newline", "I (3) am still foo\nare you still you?\n";
            };

            _out "newline", "After: I (2) am still foo\nare you still you?\n";
        };

        task "foo nested 1 again" => sub { _out "newline", "hi\n"; };

        _out "newline", "AFTER: I am foo\nWho are you?\n";
    };

    task "Bar" => sub {
        _out "no-newline", "I am bar\nAt least so far";

        task "bar nested 1" => sub {
            _out "no-newline", "Before: I (2) am still bar\nAt least so far";

            task "bar nested 2" => sub {
                _out "no-newline", "I (3) am still bar\nAt least so far";
            };

            _out "no-newline", "After: I (2) am still bar\nAt least so far";
        };

        task "bar nested 1 again" => sub { _out "no-newline", "hi"; };

        _out "no-newline", "AFTER: I am finally bar\nAt least so far";
    };

    print "I also am at depth 0\n";
};

# diag( explain($trap) );
ok($trap);

trap {
    task "I am ok" => sub {
        print "Are you ok?\n";
        task "I feel sad" => sub {
            print "I eel sad\n";
            return;
        };

        task "I feel happy" => sub {
            print "I eel happy\n";
            return 1;
        };
    };
};
like $trap->stdout, qr/done \(I feel happy\)/, "task return true is not failure";
like $trap->warn->[0], qr/failed \(I feel sad\)/, "task return false is failure";

###############
#### helpers ##
###############

sub _out {
    my ( $label, $msg ) = @_;

    print "print $label: $msg";

    print STDERR "print STDERR $label: $msg";

    printf "printf $label: %s", $msg;

    printf STDERR "printf STDERR $label: %s", $msg;

    warn "warn $label: $msg";

    say "say \$label: \$msg";
    say STDERR "say STDERR \$label: \$msg";

    return;
}

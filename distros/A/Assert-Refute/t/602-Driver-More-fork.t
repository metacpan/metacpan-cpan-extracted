#!perl

use strict;
use warnings;

if ($^O eq 'MSWin32') {
    require Test::More;
    Test::More->import;
    plan( skip_all => 'Fork not supported (yet)' );
    exit 0;
};

# Preload nothing - don't spoil test!

pipe (my $read, my $write)
    or die "Failed to open pipe: $!";
my $pid = fork;
die "Cannot fork: $!" unless defined $pid;

if (!$pid) {
    # child section first
    require Carp;
    close $read;
    open STDOUT, ">&", $write;
    open STDERR, ">&", $write;
    $| = 1;

    print STDERR "Fork\n";

    eval <<'PERL'; ## no critic # sorry, have to eval
        use strict;
        use warnings;
        use Test::More;

        use Assert::Refute qw(:core);

        current_contract()->note("Testing test::more integration");
        ok 1, "Intermix 1";
        eval {
            refute 0, "Test pass";
        };
        is $@, '', "No exception";
        ok 1, "Intermix 3";
        eval {
            refute "Big and hairy reason", "Test fail";
        };
        is $@, '', "No exception (2)";
        ok 1, "Intermix 5";
        done_testing;
        print STDERR "Done\n";
PERL
} else { # if pid
    close $write;
    $| = 1;

    require Test::More;
    Test::More->import();

    my @out;
    while (<$read>) {
        push @out, $_;
    };

    $pid == waitpid( $pid, 0 )
        or die "Failed to waitpid: $!";
    my $exit = $? >> 8;
    my $sig  = $? & 128;

    my $stdout = join '', @out;
    $stdout or die "Failed to read pipe: $!";

    # finally!
    note( "### CHILD REPLY ###" );
    note( $stdout );
    note( "### END CHILD REPLY ###" );

    is (  $exit, 1, "1 test fail + no signal" );
    is (  $sig,  0, "1 test fail + no signal" );
    like( $stdout, qr/# *Testing[^\n]*integration\n/, "Note worked");
    like( $stdout, qr/Intermix 1.*Test pass.*Intermix 3.*Test fail.*#[^\n]*Big and hairy reason.*Intermix 5.*\n1..\d+/s, "Test maybe worked" );

    unlike( $stdout, qr/not ok[^\n]*exception/, "Nothing died" );

    done_testing();
}; # end if pid

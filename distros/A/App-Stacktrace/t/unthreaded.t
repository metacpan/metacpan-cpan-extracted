#!/usr/bin/perl
use strict;

my $WAITED_PID;
my $WAITED_RC;
$SIG{CHLD} = sub {
    $WAITED_PID = wait;
    $WAITED_RC = $?;
    die 'Child exited';
};

my ( $pstack_rd, $pstack_wr );
pipe( $pstack_rd, $pstack_wr );

my ( $pstack_rd1, $pstack_wr1 );
pipe( $pstack_rd1, $pstack_wr1 );

my $pstack_ppid = $$;
my $pstack_pid = fork;
if (!defined $pstack_pid) {
    die "Can't fork: $!";
}
elsif ($pstack_pid) {
    require Test::More;
    Test::More::plan( tests => 5 );

    close $pstack_wr;
    close $pstack_rd1;
    syswrite $pstack_wr1, '.';
    my $trace = '';
    eval {
        while (!$WAITED_PID) {
            my $rin = '';
            my $ein = '';
            vec($rin, fileno($pstack_rd), 1) = 1;
            vec($ein, fileno($pstack_rd), 1) = 1;
            select $rin, undef, $ein, 60;
            if (vec $rin, fileno($pstack_rd), 1) {
                my $bytes = sysread $pstack_rd, $trace, 4096, length $trace;
                last if 0 == $bytes;
            }
            else {
                last;
            }
        }
    };

  SKIP: {
        Test::More::diag( $trace );
        if ( $trace && $trace =~ /ptrace: Operation not permitted/ ) {
            Test::More::skip("ptrace permissions", 1);
        }

        Test::More::like(
        $trace,
            qr{
                (?:
                    ^t/unthreaded\.t:\d+\n
                ){10}
            }xm
        );

    }

        Test::More::is( $WAITED_PID, $pstack_pid, "Reaped pstack" );
        Test::More::is( $WAITED_RC >> 8, 0, "exit(0)" );
        Test::More::is( $WAITED_RC & 127, 0, "No signals" );
        Test::More::is( $WAITED_RC & 128, 0, "No core dump" );
    
    exit;
}

close $pstack_rd;
close $pstack_wr1;
sysread $pstack_rd1, $_, 1;

my ( $script_rd, $script_wr );
pipe( $script_rd, $script_wr );

$SIG{CHLD} = sub { exit };
my $script_ppid = $$;
my $script_pid = fork;
if (!defined $pstack_pid) {
    die "Can't fork: $!";
}
elsif ($script_pid) {
    sysread $script_rd, $_, 1;

    require App::Stacktrace;
    open STDOUT, '>&=' . fileno( $pstack_wr );
    open STDERR, '>&=' . fileno( $pstack_wr );
    App::Stacktrace->new(
        '--exec',
        $script_pid
    )->run;
    kill 2, $script_pid;
    exit;
}

$SIG{INT} = sub { exit };
foo( 10 );
sub foo {
    my $v = shift;
    if ( $v ) {
        -- $v;
        foo( $v );
    }
    else {
        syswrite $script_wr, '.';
        while (1) {
            my $pstack_ppid_alive = kill 0, $pstack_ppid;
            my $script_ppid_alive = kill 0, $script_ppid;
            print "# Alive top @{[time]}: $pstack_ppid_alive middle: $script_ppid_alive\n";
            if ($pstack_ppid_alive && $script_ppid_alive) {
                select undef, undef, undef, 1;
            }
            else {
                exit;
            }
        }
        exit;
    }
}

use strict;
use Test::More;

use CHI;
use CHI::Cascade;

use IO::Handle;
use Storable	qw(store_fd fd_retrieve);
use Time::HiRes	qw(time);

use constant DELAY		=> 2.0;
use constant QUICK_DELAY	=> 0.5;

plan skip_all => 'Not installed CHI::Driver::Memcached::Fast'
  unless eval "use CHI::Driver::Memcached::Fast; 1";

plan skip_all => 'Memcached tests are skipped (to define FORCE_MEMCACHED_TESTS environment variable if you want)'
  unless defined $ENV{FORCE_MEMCACHED_TESTS};

my ($pid_file, $socket_file, $cwd, $user_opt);

chomp($cwd = `pwd`);

if ($< == 0) {
    # if root - other options
    $pid_file 		= "/tmp/memcached.$$.pid";
    $socket_file	= "/tmp/memcached.$$.socket";
    $user_opt		= '-u nobody';

}
else {
    $pid_file 		= "$cwd/t/memcached.$$.pid";
    $socket_file	= "$cwd/t/memcached.$$.socket";
    $user_opt		= '';
}

my $out = `memcached $user_opt -d -s $socket_file -a 644 -m 64 -P $pid_file -t 2 2>&1`;

$SIG{__DIE__} = sub {
    `{ kill \`cat $pid_file\`; } >/dev/null 2>&1`;
    unlink $pid_file	unless -l $pid_file;
    unlink $socket_file	unless -l $socket_file;
    $SIG{__DIE__} = 'IGNORE';
};

$SIG{TERM} = $SIG{INT} = $SIG{HUP} = sub { die "Terminated by " . shift };

select( undef, undef, undef, 1.0 );

if ( $? || ! (-f $pid_file )) {
    ( defined($out) && chomp($out) ) || ( $out = '' );
    plan skip_all => "Cannot start the memcached for this test ($out)";
}

my ($pid_slow, $pid_quick, $big_array_type);

setup_for_slow_process();

if ($pid_slow = fork) {
    setup_slow_parent();
}
else {
    die "cannot fork: $!" unless defined $pid_slow;
    setup_slow_child();
    run_slow_process();
}

setup_for_quick_process();

if ($pid_quick = fork) {
    setup_quick_parent();
}
else {
    die "cannot fork: $!" unless defined $pid_quick;
    setup_quick_child();
    run_quick_process();
}

# Here parent - it will command

$SIG{__DIE__} = sub {
    `{ kill \`cat $pid_file\`; } >/dev/null 2>&1`;
    kill 15, $pid_slow if $pid_slow;
    kill 15, $pid_quick if $pid_quick;
    waitpid($pid_slow, 0);
    waitpid($pid_quick, 0);
    unlink $pid_file	unless -l $pid_file;
    unlink $socket_file	unless -l $socket_file;
    $SIG{__DIE__} = 'IGNORE';
};

start_parent_commanding();

exit 0;

sub start_parent_commanding {
    plan tests => 12;

    my $in;

    print CHILD_SLOW_WTR "save1\n"		or die $!;

    select( undef, undef, undef, QUICK_DELAY );

    print CHILD_QUICK_WTR "read1\n"		or die $!;
    $in = fd_retrieve(\*CHILD_QUICK_RDR)	or die "fd_retrieve";

    ok( $in->{time2} - $in->{time1} < 0.1, 'time of read1' );
    ok( ! defined($in->{value}), 'value of read1' );

    $in = fd_retrieve(\*CHILD_SLOW_RDR);

    ok(	abs( DELAY * 2 - $in->{time2} + $in->{time1} ) < 0.1, 'time of save1' );
    ok(	defined($in->{value}), 'value of save1 defined' );
    is_deeply( $in->{value}, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], 'value of save1' );

    print CHILD_SLOW_WTR "save2\n"		or die $!;

    select( undef, undef, undef, QUICK_DELAY );

    print CHILD_QUICK_WTR "read1\n"		or die $!;
    $in = fd_retrieve(\*CHILD_QUICK_RDR)	or die "fd_retrieve";

    ok( $in->{time2} - $in->{time1} < 0.1, 'time of read1(2)' );
    is_deeply( $in->{value}, [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ], 'value of save2 before' );

    $in = fd_retrieve(\*CHILD_SLOW_RDR);

    ok(	abs( DELAY * 2 - $in->{time2} + $in->{time1} ) < 0.1, 'time of save2' );
    ok(	defined($in->{value}), 'value of save2 defined' );
    is_deeply( $in->{value}, [ 101, 102, 103, 104, 105, 106, 107, 108, 109, 110 ], 'value of save2' );

    print CHILD_QUICK_WTR "read1\n"		or die $!;
    $in = fd_retrieve(\*CHILD_QUICK_RDR)	or die "fd_retrieve";

    ok( $in->{time2} - $in->{time1} < 0.1, 'time of read1(3)' );
    is_deeply( $in->{value}, [ 101, 102, 103, 104, 105, 106, 107, 108, 109, 110 ], 'value of save2 after' );

    print CHILD_SLOW_WTR "exit\n"		or die $!;
    print CHILD_QUICK_WTR "exit\n"		or die $!;

    $SIG{__DIE__}->();
}

sub run_slow_process {
    my $line;

    my $cascade = CHI::Cascade->new(
	chi => CHI->new(
	    driver		=> 'Memcached::Fast',
	    servers		=> [$socket_file],
	    namespace		=> 'CHI::Cascade::tests'
	)
    );

    set_cascade_rules($cascade, DELAY);

    my $out;

    while ($line = <PARENT_SLOW_RDR>) {
	chomp $line;

	if ($line eq 'save1') {
	    $out = {};

	    $out->{time1} = time;
	    $out->{value} = $cascade->run('one_page_0');
	    $out->{time2} = time;
	    store_fd $out, \*PARENT_SLOW_WTR;
	}
	elsif ($line eq 'save2') {
	    $out = {};

	    $big_array_type = 1;
	    $cascade->touch('big_array_trigger');

	    $out->{time1} = time;
	    $out->{value} = $cascade->run('one_page_0');
	    $out->{time2} = time;
	    store_fd $out, \*PARENT_SLOW_WTR;
	}
	elsif ($line eq 'exit') {
	    exit 0;
	}
    }
}

sub run_quick_process {
    my $line;

    my $cascade = CHI::Cascade->new(
	chi => CHI->new(
	    driver		=> 'Memcached::Fast',
	    servers		=> [$socket_file],
	    namespace		=> 'CHI::Cascade::tests'
	)
    );

    set_cascade_rules($cascade, 0);

    my $out;

    while ($line = <PARENT_QUICK_RDR>) {
	chomp $line;

	if ($line eq 'read1') {
	    $out = {};

	    $out->{time1} = time;
	    $out->{value} = $cascade->run('one_page_0');
	    $out->{time2} = time;
	    store_fd $out, \*PARENT_QUICK_WTR;
	}
	elsif ($line eq 'exit') {
	    exit 0;
	}
    }
}

sub setup_for_slow_process {
    pipe(PARENT_SLOW_RDR, CHILD_SLOW_WTR);
    pipe(CHILD_SLOW_RDR,  PARENT_SLOW_WTR);
    CHILD_SLOW_WTR->autoflush(1);
    PARENT_SLOW_WTR->autoflush(1);
}

sub setup_for_quick_process {
    pipe(PARENT_QUICK_RDR, CHILD_QUICK_WTR);
    pipe(CHILD_QUICK_RDR,  PARENT_QUICK_WTR);
    CHILD_QUICK_WTR->autoflush(1);
    PARENT_QUICK_WTR->autoflush(1);
}

sub setup_slow_parent {
    $SIG{__DIE__} = 'IGNORE';
    close PARENT_SLOW_RDR; close PARENT_SLOW_WTR;
}

sub setup_quick_parent {
    $SIG{__DIE__} = 'IGNORE';
    close PARENT_QUICK_RDR; close PARENT_QUICK_WTR;
}

sub setup_slow_child {
    $SIG{TERM} = $SIG{INT} = $SIG{HUP} = sub { exit 1 };
    close CHILD_SLOW_RDR; close CHILD_SLOW_WTR;
}

sub setup_quick_child {
    $SIG{TERM} = $SIG{INT} = $SIG{HUP} = sub { exit 1 };
    close CHILD_QUICK_RDR; close CHILD_QUICK_WTR;
}

sub set_cascade_rules {
    my ($cascade, $delay) = @_;

    $cascade->rule(
	target		=> 'big_array_trigger',
	code		=> sub {
	    return [];
	}
    );

    $cascade->rule(
	target		=> 'big_array',
	depends		=> 'big_array_trigger',
	code		=> sub {
	    select( undef, undef, undef, $delay )
	      if ($delay);

	    return $big_array_type ? [ 101 .. 1000 ] : [ 1 .. 1000 ];
	}
    );

    $cascade->rule(
	target		=> qr/^one_page_(\d+)$/,
	depends		=> 'big_array',
	code		=> sub {
	    my ($rule, $target, $values) = @_;

	    my ($page) = $target =~ /^one_page_(\d+)$/;

	    select( undef, undef, undef, $delay )
	      if ($delay);

	    my $ret = [ @{$values->{big_array}}[ ($page * 10) .. (( $page + 1 ) * 10 - 1) ] ];
	    $ret;
	}
    );
}

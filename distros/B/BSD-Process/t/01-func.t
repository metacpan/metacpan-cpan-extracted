# 01-func.t
# Test the public BSD::Process routines
#
# Copyright (C) 2006-2011 David Landgren

use strict;
use Test::More;

use BSD::Process;
plan tests => 152 + scalar(BSD::Process::attr());

use Config;

my $Unchanged = 'The scalar remains the same';
$_ = $Unchanged;

my $RUNNING_ON_FREEBSD_4 = $Config{osvers} =~ /^4/;
my $RUNNING_ON_FREEBSD_5 = $Config{osvers} =~ /^5/;

my $info = BSD::Process::info();

# remove all attributes from object, should be none left over
ok( defined( delete $info->{pid} ), 'attribute pid');
ok( defined( delete $info->{ppid} ), 'attribute ppid');
ok( defined( delete $info->{pgid} ), 'attribute pgid');
ok( defined( delete $info->{tpgid} ), 'attribute tpgid');
ok( defined( delete $info->{sid} ), 'attribute sid');
ok( defined( delete $info->{jobc} ), 'attribute jobc');
ok( defined( delete $info->{rssize} ), 'attribute rssize');
ok( defined( delete $info->{swrss} ), 'attribute swrss');
ok( defined( delete $info->{tsize} ), 'attribute tsize');
ok( defined( delete $info->{xstat} ), 'attribute xstat');
ok( defined( delete $info->{acflag} ), 'attribute acflag');
ok( defined( delete $info->{pctcpu} ), 'attribute pctcpu');
ok( defined( delete $info->{estcpu} ), 'attribute estcpu');
ok( defined( delete $info->{slptime} ), 'attribute slptime');
ok( defined( delete $info->{swtime} ), 'attribute swtime');
ok( defined( delete $info->{runtime} ), 'attribute runtime');
ok( defined( delete $info->{flag} ), 'attribute flag');
ok( defined( delete $info->{nice} ), 'attribute nice');
ok( defined( delete $info->{lock} ), 'attribute lock');
ok( defined( delete $info->{rqindex} ), 'attribute rqindex');
ok( defined( delete $info->{oncpu} ), 'attribute oncpu');
ok( defined( delete $info->{lastcpu} ), 'attribute lastcpu');
ok( defined( delete $info->{wmesg} ), 'attribute wmesg');
ok( defined( delete $info->{login} ), 'attribute login');
ok( defined( delete $info->{comm} ), 'attribute comm');

ok( defined( delete $info->{args} ), 'attribute args');
ok( defined( delete $info->{tsid} ), 'attribute tsid');
ok( defined( delete $info->{uid} ), 'attribute uid');
ok( defined( delete $info->{ruid} ), 'attribute ruid');
ok( defined( delete $info->{svuid} ), 'attribute svuid');
ok( defined( delete $info->{rgid} ), 'attribute rgid');
ok( defined( delete $info->{svgid} ), 'attribute svgid');
ok( defined( delete $info->{size} ), 'attribute size');
ok( defined( delete $info->{dsize} ), 'attribute dsize');
ok( defined( delete $info->{ssize} ), 'attribute ssize');
ok( defined( delete $info->{start} ), 'attribute start');
ok( defined( delete $info->{childtime} ), 'attribute childtime');
ok( defined( delete $info->{advlock} ), 'attribute advlock');
ok( defined( delete $info->{controlt} ), 'attribute controlt');
ok( defined( delete $info->{kthread} ), 'attribute kthread');
ok( defined( delete $info->{noload} ), 'attribute noload');
ok( defined( delete $info->{ppwait} ), 'attribute ppwait');
ok( defined( delete $info->{profil} ), 'attribute profil');
ok( defined( delete $info->{stopprof} ), 'attribute stopprof');
ok( defined( delete $info->{sugid} ), 'attribute sugid');
ok( defined( delete $info->{system} ), 'attribute system');
ok( defined( delete $info->{single_exit} ), 'attribute single_exit');
ok( defined( delete $info->{traced} ), 'attribute traced');
ok( defined( delete $info->{waited} ), 'attribute waited');
ok( defined( delete $info->{wexit} ), 'attribute wexit');
ok( defined( delete $info->{exec} ), 'attribute exec');
ok( defined( delete $info->{kiflag} ), 'attribute kiflag');
ok( defined( delete $info->{locked} ), 'attribute locked');
ok( defined( delete $info->{isctty} ), 'attribute isctty');
ok( defined( delete $info->{issleader} ), 'attribute issleader');
ok( defined( delete $info->{stat} ), 'attribute stat');
ok( defined( delete $info->{stat_1} ), 'attribute stat_1');
ok( defined( delete $info->{stat_2} ), 'attribute stat_2');
ok( defined( delete $info->{stat_3} ), 'attribute stat_3');
ok( defined( delete $info->{stat_4} ), 'attribute stat_4');
ok( defined( delete $info->{stat_5} ), 'attribute stat_5');
ok( defined( delete $info->{stat_6} ), 'attribute stat_6');
ok( defined( delete $info->{stat_7} ), 'attribute stat_7');
ok( defined( delete $info->{ocomm} ), 'attribute ocomm');
ok( defined( delete $info->{lockname} ), 'attribute lockname');
ok( defined( delete $info->{pri_class} ), 'attribute pri_class');
ok( defined( delete $info->{pri_level} ), 'attribute pri_level');
ok( defined( delete $info->{pri_native} ), 'attribute pri_native');
ok( defined( delete $info->{pri_user} ), 'attribute pri_user');
ok( defined( delete $info->{utime} ), 'attribute utime');
ok( defined( delete $info->{stime} ), 'attribute stime');
ok( defined( delete $info->{time} ), 'attribute time (utime+stime)');
ok( defined( delete $info->{maxrss} ), 'attribute maxrss');
ok( defined( delete $info->{ixrss} ), 'attribute ixrss');
ok( defined( delete $info->{idrss} ), 'attribute idrss');
ok( defined( delete $info->{isrss} ), 'attribute isrss');
ok( defined( delete $info->{minflt} ), 'attribute minflt');
ok( defined( delete $info->{majflt} ), 'attribute majflt');
ok( defined( delete $info->{nswap} ), 'attribute nswap');
ok( defined( delete $info->{inblock} ), 'attribute inblock');
ok( defined( delete $info->{oublock} ), 'attribute oublock');
ok( defined( delete $info->{msgsnd} ), 'attribute msgsnd');
ok( defined( delete $info->{msgrcv} ), 'attribute msgrcv');
ok( defined( delete $info->{nsignals} ), 'attribute nsignals');
ok( defined( delete $info->{nvcsw} ), 'attribute nvcsw');
ok( defined( delete $info->{nivcsw} ), 'attribute nivcsw');

ok( defined( delete $info->{hadthreads} ), 'attribute hadthreads');
ok( defined( delete $info->{emul} ), 'attribute emul');
ok( defined( delete $info->{jid} ), 'attribute jid');
ok( defined( delete $info->{numthreads} ), 'attribute numthreads');
ok( defined( delete $info->{utime_ch} ), 'attribute utime_ch');
ok( defined( delete $info->{stime_ch} ), 'attribute stime_ch');
ok( defined( delete $info->{time_ch} ), 'attribute time_ch (utime_ch+stime_ch)');
ok( defined( delete $info->{maxrss_ch} ), 'attribute maxrss_ch');
ok( defined( delete $info->{ixrss_ch} ), 'attribute ixrss_ch');
ok( defined( delete $info->{idrss_ch} ), 'attribute idrss_ch');
ok( defined( delete $info->{isrss_ch} ), 'attribute isrss_ch');
ok( defined( delete $info->{minflt_ch} ), 'attribute minflt_ch');
ok( defined( delete $info->{majflt_ch} ), 'attribute majflt_ch');
ok( defined( delete $info->{nswap_ch} ), 'attribute nswap_ch');
ok( defined( delete $info->{inblock_ch} ), 'attribute inblock_ch');
ok( defined( delete $info->{oublock_ch} ), 'attribute oublock_ch');
ok( defined( delete $info->{msgsnd_ch} ), 'attribute msgsnd_ch');
ok( defined( delete $info->{msgrcv_ch} ), 'attribute msgrcv_ch');
ok( defined( delete $info->{nsignals_ch} ), 'attribute nsignals_ch');
ok( defined( delete $info->{nvcsw_ch} ), 'attribute nvcsw_ch');
ok( defined( delete $info->{nivcsw_ch} ), 'attribute nivcsw_ch');

my $ngroups;
ok( defined( $ngroups = delete $info->{ngroups} ), 'attribute ngroups');

# attribute returning non-scalars

my $grouplist = delete $info->{groups};
ok( defined($grouplist), 'attribute groups' );
is( ref($grouplist), 'ARRAY', q{... it's a list} );
if ($RUNNING_ON_FREEBSD_4) {
    pass("... of the expected size (unknowable on FreeBSD 4.x)");
}
else {
    is( scalar(@$grouplist), $ngroups, "... of the expected size" )
        or diag("grouplist = (@$grouplist)");
}

# check for typos in hv_store calls in Process.xs
is( scalar(keys %$info), 0, 'all attributes have been accounted for' )
    or diag( 'leftover: ' . join( ',', keys %$info ));

my @attribute = BSD::Process::attr;
my $max_len = 0;
my $proc    = BSD::Process::info();
my $exists  = 0;
for my $attr (@attribute) {
    if ($max_len < length($attr)) {
        $max_len = length($attr);
    }
    if (exists $proc->{$attr}) {
        pass("lookup $attr");
        delete $proc->{$attr};
        ++$exists;
    }
    else {
        fail("lookup $attr");
    }
}
is($max_len, BSD::Process::attr_len, 'length of longest attribute');
is($exists, scalar(@attribute), "all lookups exist");
is(scalar(grep {!/^_/} keys %$proc), 0, 'nothing left to look up');

is(scalar(@attribute), scalar(BSD::Process::attr_alias), 'attributes and aliases');

my @all = BSD::Process::list();
my $all_procs = @all;
cmp_ok( scalar(@all), '>', 10, "list of all processes ($all_procs)" )
    or diag("proclist: (@all)");

# processes owned by a uid
SKIP: {
    skip( "not supported on FreeBSD 4.x", 4 )
        if $RUNNING_ON_FREEBSD_4;
    # count the processes owned by each uid
    my %uid;
    for my $pid (@all) {
        my $proc = BSD::Process->new($pid);
        if ($proc) {
            diag( "proc $proc->{_pid} is a zombie" )
                if exists $proc->{_pid} and not exists $proc->{pid};
            $uid{$proc->{uid}}++;
        }
        else {
            diag( "new() failed for pid $pid" );
        }
    }

    # now find the uids that own the most processes
    my ($biggest, $bigger) = (sort {$uid{$b} <=> $uid{$a} || $a <=> $b} keys %uid )[0,1];

    my @proc = BSD::Process::list( uid => $biggest );
    cmp_ok( scalar(@proc), '<', $all_procs, "uid $biggest smaller than count of all processes" );

    my $biggest_uid = @proc;
    @proc = BSD::Process::list( effective_user_id => $bigger );
    cmp_ok( scalar(@proc), '<',  $all_procs, "uid $bigger smaller than count of all processes" );
    cmp_ok( scalar(@proc), '<=', $biggest_uid, "uid $bigger smaller or equal to uid $biggest" );

    my $all_uid = BSD::Process::all( uid => $biggest );
    my $total = scalar(keys %$all_uid);
    my $same_uid = 0;
    for my $proc (keys %$all_uid) {
        ++$same_uid if $all_uid->{$proc}{uid} == $biggest;
    }
    is ($total, $same_uid, "same number of processes for uid $biggest" )
        or do {
            diag( "pid: $_ uid: all_uid->{$_}{uid}" )
                for keys %$all_uid;
        };
}

# processes owned by a ruid
SKIP: {
    skip( "not supported on FreeBSD 4.x", 5 )
        if $RUNNING_ON_FREEBSD_4;
    # count the processes owned by each real uid
    my %ruid;
    for my $pid (@all) {
        my $proc = BSD::Process->new($pid);
        $ruid{$proc->{ruid}}++ if defined $proc->{ruid};
    }

    # now find the uids that own the most processes
    my ($biggest, $bigger) = (sort {$ruid{$b} <=> $ruid{$a} || $a <=> $b} keys %ruid )[0,1];

    my @proc = BSD::Process::list( ruid => $biggest );
    cmp_ok( scalar(@proc), '<', $all_procs, "ruid $biggest smaller than count of all processes" );

    my $biggest_ruid = @proc;
    @proc = BSD::Process::list( real_user_id => $bigger );
    cmp_ok( scalar(@proc), '<',  $all_procs, "ruid $bigger smaller than count of all processes" );
    cmp_ok( scalar(@proc), '<=', $biggest_ruid, "ruid $bigger smaller or equal to ruid $biggest" );

    my $all_ruid = BSD::Process::all( resolve => 1, ruid => $bigger );
    my $total = keys %$all_ruid;
    my $same_uid = 0;
    my $blessed  = 0;
    for my $proc (keys %$all_ruid) {
        ++$same_uid if scalar(getpwnam($all_ruid->{$proc}{ruid})) == $bigger;
        ++$blessed if ref($all_ruid->{$proc}) eq 'BSD::Process';
    }
    is ($total, $same_uid, "same number of processes for ruid $bigger" )
        or do {
            diag( "pid: $_ uid: $all_ruid->{$_}{uid}" )
                for keys %$all_ruid;
        };

    is ($total, $blessed, "... and all blessed BSD::Process objects" );
}

SKIP: {
    # processes owned by an effective gid
    skip( "not supported on FreeBSD 4.x or 5.x", 6 )
        if $RUNNING_ON_FREEBSD_4 or $RUNNING_ON_FREEBSD_5;
    # count the processes owned by each effective gid
    # kinfo_proc lacks a gid field, so we'll punt with a real gid
    my %gid;
    for my $pid (@all) {
        my $proc = BSD::Process->new($pid);
        $gid{$proc->{rgid}}++ if defined $proc->{rgid};
    }

    # now find the gids that own the most processes
    my ($biggest, $bigger) = (sort {$gid{$b} <=> $gid{$a} || $a <=> $b} keys %gid )[0,1];

    my @proc = BSD::Process::list( gid => $biggest );
    cmp_ok( scalar(@proc), '<', $all_procs, "gid $biggest smaller than count of all processes" );

    my $biggest_gid = @proc;
    @proc = BSD::Process::list( effective_group_id => $bigger );
    cmp_ok( scalar(@proc), '<',  $all_procs, "gid $bigger smaller than count of all processes" );
    cmp_ok( scalar(@proc), '<=', $biggest_gid, "gid $bigger smaller or equal to gid $biggest" );

    # processes owned by a rgid
    my %rgid;
    for my $pid (@all) {
        my $proc = BSD::Process->new($pid);
        $rgid{$proc->{rgid}}++ if defined $proc->{rgid};
    }

    # now find the gids that own the most processes
    ($biggest, $bigger) = (sort {$rgid{$b} <=> $rgid{$a} || $a <=> $b} keys %rgid )[0,1];

    @proc = BSD::Process::list( rgid => $biggest );
    cmp_ok( scalar(@proc), '<', $all_procs, "rgid $biggest smaller than count of all processes" );

    my $biggest_rgid = @proc;
    @proc = BSD::Process::list( real_group_id => $bigger );
    cmp_ok( scalar(@proc), '<',  $all_procs, "rgid $bigger smaller than count of all processes" );
    cmp_ok( scalar(@proc), '<=', $biggest_rgid, "rgid $bigger smaller or equal to rgid $biggest" );
}

# process groups
SKIP: {
    skip( "not supported on FreeBSD 4.x", 6 )
        if $RUNNING_ON_FREEBSD_4;
    # count the processes in each process group
    my %pgid;
    for my $pid (@all) {
        my $proc = BSD::Process->new($pid);
        $pgid{$proc->{pgid}}++ if defined $proc->{pgid};
    }

    # now find the process groups with the most members
    my ($biggest, $bigger) = (sort {$pgid{$b} <=> $pgid{$a} || $a <=> $b} keys %pgid )[0,1];

    my @proc = BSD::Process::list( pgid => $biggest );
    cmp_ok( scalar(@proc), '<', $all_procs, "pgid $biggest smaller than count of all processes" );

    my $biggest_pgid = @proc;
    @proc = BSD::Process::list( process_group_id => $bigger );
    cmp_ok( scalar(@proc), '<',  $all_procs, "pgid $bigger smaller than count of all processes" );
    cmp_ok( scalar(@proc), '<=', $biggest_pgid, "pgid $bigger smaller or equal to pgid $biggest" );

    # process sessions
    # count the processes in each process session
    my %sid;
    for my $pid (@all) {
        my $proc = BSD::Process->new($pid);
        $sid{$proc->{sid}}++ if defined $proc->{sid};
    }

    # now find the process groups with the most members
    ($biggest, $bigger) = (sort {$sid{$b} <=> $sid{$a} || $a <=> $b} keys %sid )[0,1];

    @proc = BSD::Process::list( sid => $biggest );
    cmp_ok( scalar(@proc), '<', $all_procs, "sid $biggest smaller than count of all processes" );

    my $biggest_sid = @proc;
    @proc = BSD::Process::list( process_session_id => $bigger );
    cmp_ok( scalar(@proc), '<',  $all_procs, "sid $bigger smaller than count of all processes" );
    cmp_ok( scalar(@proc), '<=', $biggest_sid, "sid $bigger smaller or equal to sid $biggest" );
}

$info = BSD::Process::info($$);
is( $info->{pid}, $$, "system says my pid is the same ($$)" );
isnt( $info->{pid}, $info->{ppid}, 'I am not my parent' );

my $parent = BSD::Process::info($info->{ppid});
is( $parent->{pid}, $info->{ppid}, 'my parent is indeed my parent' );
isnt( $info->{pid}, $parent->{ppid}, 'I am not my grandparent' );
isnt( $parent->{pid}, $parent->{ppid}, 'and my parent is not my grandparent' );

SKIP: {
    skip( "not supported on FreeBSD 4.x", 6 )
        if $RUNNING_ON_FREEBSD_4;

    my $resolved = BSD::Process::info({resolve => 1});
    is( $resolved->{uid}, scalar(getpwuid($info->{uid})), 'resolve implicit pid' );

    $resolved = BSD::Process::info($info->{pid}, {resolve => 1});
    is( $resolved->{uid}, scalar(getpwuid($info->{uid})), 'resolve explicit pid' );

    my $root = BSD::Process::all( uid => 'root' );
    my $uid_root_count = 0;
    $root->{$_}->uid == 0 and ++$uid_root_count for keys %$root;
    is( $uid_root_count, scalar(keys %$root), q{counted all uid root's processes} );

    $root = BSD::Process::all( effective_user_id => 'root' );
    $uid_root_count = 0;
    $root->{$_}->uid == 0 and ++$uid_root_count for keys %$root;
    is( $uid_root_count, scalar(keys %$root), q{counted all effective uid root's processes} );

    $root = BSD::Process::all( ruid => 'root' );
    $uid_root_count = 0;
    for (keys %$root) {
        if ($root->{$_}->uid == 0) {
            ++$uid_root_count;
        }
        elsif ($root->{$_}->ruid == 0) {
            ++$uid_root_count;
            $ENV{PERL_AUTHOR_TESTING}
                and diag("root proc $_ has uid " . $root->{$_}->uid . "/" . $root->{$_}->ruid  );
        }
    }
    is( $uid_root_count, scalar(keys %$root), q{counted all ruid root's processes} );

    $root = BSD::Process::all( real_user_id => 'root' );
    $uid_root_count = 0;
    $root->{$_}->ruid == 0 and ++$uid_root_count for keys %$root;
    is( $uid_root_count, scalar(keys %$root), q{counted all real_user_id root's processes} );
}

SKIP: {
    skip( "not supported on FreeBSD 4.x or 5.x", 2 )
        if $RUNNING_ON_FREEBSD_4 or $RUNNING_ON_FREEBSD_5;

    my $wheel_gid = getgrnam('wheel');
    {
        my $wheel = BSD::Process::all( gid => 'wheel' );
        my $gid_wheel_count = 0;
        for my $pid (keys %$wheel) {
            my $proc = $wheel->{$pid};
            if ($proc->rgid == $wheel_gid) {
                 ++$gid_wheel_count;
            }
            else {
                my $msg = "$proc->{comm}($proc->{pid}) has rgid $proc->{rgid} not $wheel_gid";
                if ($proc->{comm} eq 'sshd') {
                    # sshd uses process separation, which throws this off
                    ++$gid_wheel_count;
                    $msg .= " (pass)";
                }
                $ENV{PERL_AUTHOR_TESTING} and diag( $msg );
            }
        }
        is( $gid_wheel_count, scalar(keys %$wheel), q{counted all gid wheel's processes} );
    }

    {
        my $wheel = BSD::Process::all( effective_group_id => 'wheel' );
        my $gid_wheel_count = 0;
        for my $pid (keys %$wheel) {
            my $proc = $wheel->{$pid};
            if ($proc->rgid == $wheel_gid) {
                 ++$gid_wheel_count;
            }
            else {
                my $msg = "$proc->{comm}($proc->{pid}) has rgid $proc->{rgid} not $wheel_gid";
                if ($proc->{comm} eq 'sshd') {
                    # sshd uses process separation, which throws this off
                    ++$gid_wheel_count;
                    $msg .= " (pass)";
                }
                $ENV{PERL_AUTHOR_TESTING} and diag( $msg );
            }
        }

        is( $gid_wheel_count, scalar(keys %$wheel), q{counted all effective_group_id wheel's processes} );
    }
}

is($_, $Unchanged, $Unchanged);

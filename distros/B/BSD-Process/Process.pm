# BSD::Process.pm
#
# Copyright (c) 2006-2013 David Landgren
# All rights reserved

package BSD::Process;

use strict;
use warnings;

use Exporter;
use XSLoader;
use base qw(Class::Accessor);

use vars qw($VERSION @ISA @EXPORT_OK);
$VERSION = '0.07';
@ISA = qw(Exporter Class::Accessor);

@EXPORT_OK = (qw(process_info process_list P));

BEGIN {
    my %alias = (
        process_pid              => 'pid',
        parent_pid               => 'ppid',
        process_group_id         => 'pgid',
        tty_process_group_id     => 'tpgid',
        process_session_id       => 'sid',
        job_control_counter      => 'jobc',
        resident_set_size        => 'rssize',
        rssize_before_swap       => 'swrss',
        text_size                => 'tsize',
        exit_status              => 'xstat',
        accounting_flags         => 'acflag',
        percent_cpu              => 'pctcpu',
        estimated_cpu            => 'estcpu',
        sleep_time               => 'slptime',
        time_last_swap           => 'swtime',
        elapsed_time             => 'runtime',
        process_flags            => 'flag',
        nice_priority            => 'nice',
        process_lock_count       => 'lock',
        run_queue_index          => 'rqindex',
        current_cpu              => 'oncpu',
        last_cpu                 => 'lastcpu',
        wchan_message            => 'wmesg',
        setlogin_name            => 'login',
        command_name             => 'comm',
        process_args             => 'args',
        terminal_session_id      => 'tsid',
        effective_user_id        => 'uid',
        real_user_id             => 'ruid',
        saved_effective_user_id  => 'svuid',
        real_group_id            => 'rgid',
        saved_effective_group_id => 'svgid',
        number_of_groups         => 'ngroups',
        group_list               => 'groups',
        virtual_size             => 'size',
        data_size                => 'dsize',
        stack_size               => 'ssize',
        start_time               => 'start',
        children_time            => 'childtime',
        posix_advisory_lock      => 'advlock',
        has_controlling_terminal => 'controlt',
        is_kernel_thread         => 'kthread',
        no_loadavg_calc          => 'noload',
        parent_waiting           => 'ppwait',
        started_profiling        => 'profil',
        stopped_profiling        => 'stopprof',
        id_privs_set             => 'sugid',
        system_process           => 'system',
        single_exit_not_wait     => 'single_exit',
        traced_by_debugger       => 'traced',
        waited_on_by_other       => 'waited',
        working_on_exiting       => 'wexit',
        process_called_exec      => 'exec',
        kernel_session_flag      => 'kiflag',
        is_locked                => 'locked',
        controlling_tty_active   => 'isctty',
        is_session_leader        => 'issleader',
        process_status           => 'stat',
        is_being_forked          => 'stat_1',
        is_runnable              => 'stat_2',
        is_sleeping_on_addr      => 'stat_3',
        is_stopped               => 'stat_4',
        is_a_zombie              => 'stat_5',
        is_waiting_on_intr       => 'stat_6',
        is_blocked               => 'stat_7',
        old_command_name         => 'ocomm',
        name_of_lock             => 'lockname',
        priority_scheduling_class => 'pri_class',
        priority_level            => 'pri_level',
        priority_native           => 'pri_native',
        priority_user             => 'pri_user',
        user_time                 => 'utime',
        system_time               => 'stime',
        total_time                => 'time',
        max_resident_set_size     => 'maxrss',
        shared_memory_size        => 'ixrss',
        unshared_data_size        => 'idrss',
        unshared_stack_size       => 'isrss',
        page_reclaims             => 'minflt',
        page_faults               => 'majflt',
        number_of_swaps           => 'nswap',
        block_input_ops           => 'inblock',
        block_output_ops          => 'oublock',
        messages_sent             => 'msgsnd',
        messages_received         => 'msgrcv',
        signals_received          => 'nsignals',
        voluntary_context_switch   => 'nvcsw',
        involuntary_context_switch => 'nivcsw',
        process_had_threads        => 'hadthreads',
        emulation_name             => 'emul',
        process_jail_id            => 'jid',
        number_of_threads          => 'numthreads',
        user_time_ch               => 'utime_ch',
        system_time_ch             => 'stime_ch',
        total_time_ch              => 'time_ch',
        max_resident_set_size_ch   => 'maxrss_ch',
        shared_memory_size_ch      => 'ixrss_ch',
        unshared_data_size_ch      => 'idrss_ch',
        unshared_stack_size_ch     => 'isrss_ch',
        page_reclaims_ch           => 'minflt_ch',
        page_faults_ch             => 'majflt_ch',
        number_of_swaps_ch         => 'nswap_ch',
        block_input_ops_ch         => 'inblock_ch',
        block_output_ops_ch        => 'oublock_ch',
        messages_sent_ch           => 'msgsnd_ch',
        messages_received_ch       => 'msgrcv_ch',
        signals_received_ch        => 'nsignals_ch',
        voluntary_context_switch_ch   => 'nvcsw_ch',
        involuntary_context_switch_ch => 'nivcsw_ch',
    );

    # make some shorthand accessors
    BSD::Process->mk_ro_accessors( values %alias );

    # and map some longhand aliases to them
    no strict 'refs';
    for my $long (keys %alias) {
        *{$long} = *{$alias{$long}};
    }

    sub attr {
        return values(%alias);
    }

    sub attr_len {
        my $len = 0;
        for my $attr(values %alias) {
            $len = length($attr) if $len < length($attr);
        }
        return $len;
    }

    sub attr_alias {
        return keys(%alias);
    }
}

XSLoader::load __PACKAGE__, $VERSION;

sub new {
    my $class = shift;
    my $pid   = shift;
    my $args;
    if (ref($pid) eq 'HASH') {
        $args = $pid;
        $pid  = $$;
    }
    else {
        $args = shift || {};
    }
    $pid = $$ unless defined $pid;
    my $self = {
        _pid  => $pid
    };
    $self->{_resolve} = exists $args->{resolve} ? $args->{resolve} : 0;
    my $info = _info($self->{_pid}, $self->{_resolve});
    @{$self}{keys %$info} = values %$info;

    return bless $self, $class;
}

sub resolve {
    my $self = shift;
    $self->{_resolve} = $_[0] ? $_[0] : 1;
    return $self->refresh;
}

sub refresh {
    my $self = shift;
    my $info = _info($self->{_pid}, $self->{_resolve});
    @{$self}{keys %$info} = values %$info;
    return $self;
}

sub _request {
    my %arg = @_;
    my $request = 0;
    my $param   = 0;
    if (exists $arg{uid}) {
        $request = 5;
        $param   = $arg{uid};
        $param =~ /\D/ and $param = scalar(getpwnam($param));
    }
    elsif (exists $arg{effective_user_id}) {
        $request = 5;
        $param   = $arg{effective_user_id};
        $param =~ /\D/ and $param = scalar(getpwnam($param));
    }
    elsif (exists $arg{ruid}) {
        $request = 6;
        $param   = $arg{ruid};
        $param =~ /\D/ and $param = scalar(getpwnam($param));
    }
    elsif (exists $arg{real_user_id}) {
        $request = 6;
        $param   = $arg{real_user_id};
        $param =~ /\D/ and $param = scalar(getpwnam($param));
    }
    elsif (exists $arg{gid}) {
        $request = 11;
        $param   = $arg{gid};
        $param =~ /\D/ and $param = scalar(getgrnam($param));
    }
    elsif (exists $arg{effective_group_id}) {
        $request = 11;
        $param   = $arg{effective_group_id};
        $param =~ /\D/ and $param = scalar(getgrnam($param));
    }
    elsif (exists $arg{rgid}) {
        $request = 10;
        $param   = $arg{rgid};
        $param =~ /\D/ and $param = scalar(getgrnam($param));
    }
    elsif (exists $arg{real_group_id}) {
        $request = 10;
        $param   = $arg{real_group_id};
        $param =~ /\D/ and $param = scalar(getgrnam($param));
    }
    elsif (exists $arg{pgid}) {
        $request = 2;
        $param   = $arg{pgid};
    }
    elsif (exists $arg{process_group_id}) {
        $request = 2;
        $param   = $arg{process_group_id};
    }
    elsif (exists $arg{sid}) {
        $request = 2;
        $param   = $arg{sid};
    }
    elsif (exists $arg{process_session_id}) {
        $request = 2;
        $param   = $arg{process_session_id};
    }
    return ($request, $param);
}

sub list {
    return _list(_request(@_));
}

sub all {
    my %args = @_;
    my $resolve = exists $args{resolve} ? delete($args{resolve}) : 0;
    return _all($resolve, _request(%args));
}

sub info {
    my $pid = shift;
    my $args;
    if (ref($pid) eq 'HASH') {
        $args = $pid;
        $pid  = $$;
    }
    else {
        $args = shift || {};
    }
    $pid = $$ unless defined $pid;
    my $resolve = exists $args->{resolve} ? $args->{resolve} : 0;
    return _info($pid, $resolve);
}

{
    my $P;
    sub P {
        if ($_[0]) {
            $P = BSD::Process->new($_[0]);
        }
        elsif (!$P) {
            $P = BSD::Process->new();
        }
        return $P;
    }
}

*process_info = *info;
*process_list = *list;

=head1 NAME

BSD::Process - Information about running processes on BSD platforms

=head1 VERSION

This document describes version 0.07 of BSD::Process,
released 2013-06-22.

=head1 SYNOPSIS

  use BSD::Process;

  my $proc = BSD::Process->new;
  print $proc->rssize, " resident set size\n"; # as a method
  print "This process has made $proc->{minflt} page reclaims\n";

  print $proc->time, " seconds spent on the CPU (user+system)\n";
  $proc->refresh;
  print "And now $proc->{time} seconds\n"; # as an attribute

  # oneliner shortcut
  perl -MBSD::Process=P -le 'print P->ppid, " is my parent"';

=head1 DESCRIPTION

C<BSD::Process> creates Perl objects that render the information
the BSD kernel maintains about current processes.  These may then
be queried, extracted and reported upon. This allows a more natural
style of programming (as opposed to scraping the output of ps(1)).

The information is retrieved via the C<kvm> subsystem, and will
thus work even if the F</proc> filesystem is not mounted.

=head1 FUNCTIONS

=over 4

=item new

Creates a new C<BSD::Process> object. Takes an optional numeric
value to specify the pid of the target process, otherwise the
current process is assumed.

A second optional parameter, a reference to a hash, supplies
additional information governing the creation of the object.

Currently, one key is available:

B<resolve> - indicates whether uids and gids should be resolved to
their symbolic equivalents (for instance, 0 becomes "root").

Passing the hash reference as the only parameter works as may be
expected: the pid of the current process will be used implicitly.

  my $init = BSD::Process->new(1); # get info about init
  print "children of init have taken $init->{childtime} seconds\n";

  # get process info of process's parent, resolving ids
  my $parent = BSD::Process->new(
    BSD::Process->new->parent_pid,
    {resolve => 1},
  );

Once the object has been created, the various process attributes
can be examined via method calls or as hash keys, see below.

At the current time C<new> is implemented in terms of C<info> (see
below), but may in the future be implemented in terms of lazy
fetching.

=item P

Stashes a global BSD::Process variable, for use in one-liners. By
default, the current process is referenced, but any process may
be specified via its process id.

  print P->rssize, "\n"; # resident set size of running process
  P(P->ppid);            # now refer to parent
  print P->rssize, "\n"; # rss of parent
  P(1);                  # talking about init(8)

But more likely:

  perl -MBSD::Process=P -le 'print P->rssize';

As this function is implemented in terms of a global private
variable, it is adequate for oneliners. It should not be used in
a threaded program, use objects instead.

=item info, process_info

Returns the entire set of process attributes and their values,
as specified by a process identifier (or I<pid>).

The input value is numified. Thus, if a some random string is passed
in, it will be coerced to 0, and you will receive the process
information of process 0 (the swapper). If no parameter is passed,
the pid of the running process is assumed.

A hash reference may be passed as an optional second parameter,
see C<new> for a list of what is available.

  my $proc = BSD::Process::info( $$, {resolve => 1} );
  print $proc->{uid};
  # on my system, prints 'david', rather than 1001

A reference to a hash is returned, which is basically a C<BSD::Process>
object, without all the object-oriented fluff around it. The keys
are documented below in the METHODS section, however, only the short
names are available, the longer descriptive names are not defined.

If the pid does not (or does no longer) correspond to process, undef
is returned.

The routine C<info> is not exportable (since many programs will
no doubt already have a routine named C<info>). Instead, it is
exportable under the name C<process_info>.

=item list, process_list

Returns an (unsorted) array of pids of all the running processes
on the system. Note: fleet-footed processes may have disappeared
between the time the snapshot is taken and the time the code
subsequently gets around to asking for more information about
them. On the other hand, getting this list is very fast. If you
want the set of current processes on the system decoded as
C<BSD::Process> objects, you should be looking at the C<all>
meta-constructor.

The routine C<list> is not exportable. It may be exported under
the name C<process_info>.

  my @pid = BSD::Process::list;
  for my $p (@pid) {
    my $proc =  BSD::Process::info($p);
    print "$p $proc->{ppid}\n"; # print each pid and its parent pid
  }

The set of processes may be restricted by specifying a condition,
defined as a key/value pair to C<list()>. The following restrictions
are available:

=over 4

=item uid, effective_user_id

Return the list of pids that are owned by the specified effective
user id. The uid may be specified in the symbolic or numeric form.

  my @uid_pid  = BSD::Process::list(uid => 1001);
  my @root_pid = BSD::Process::list(uid => 'root');

=item pgid, process_group_id

Return the processes that belong to the specified process group.

  my @pgid_pid = BSD::Process::list(process_group_id => 378);

=item sid, process_session_id

Return the processes that belong to the specified process session.

=back

=item all

Return a references to a hash of C<BSD::Process> objects representing the
current running processes. The hash keys are the process pids.
The following program prints out the 10 processes that consume the most
physical memory.

  use BSD::Process;

  my $all = BSD::Process::all;
  my $want = 10;
  for my $pid (
    sort {$all->{$b}{rssize} <=> $all->{$a}{rssize}}
    keys %$all
  ) {
    my $proc = $all->{$pid};
    print $proc->command_name, ' ',  $proc->resident_set_size,
      "Kb owned by $proc->{login}\n";
    last unless --$want;
  }

This routine runs more slowly than C<list()>, since it has to
instantiate the process objects. It may help to think of C<all()>
as a meta-new constructor, since it creates many new BSD::Process
objects in one fell swoop.

This routine accepts the same parameters as C<list()>. Thus, one is
able to restrict the set of objects returned. In addition, it also
accepts the C<resolve> parameter, to indicate that uids and gids
should be represented as symbolic names rather than numeric values.

  my @own = BSD::Process::all(uid => 1000);

  my @session = BSD::Process::all(sid => 632, resolve => 1);

=item attr

Returns the list of available attributes of a C<BSD::Process>
object. You can use this to pretty-print an object:

  my $self = BSD::Process->new;
  for my $attr (BSD::Process::attr) {
    printf "%11s %s\n", $attr, $self->{$attr};
  }

=item attr_len

The problem with the above program is that on different platforms
and operating system versions, the length of the longest attribute
might not be 11.  In this case, one may employ C<attr_len> to obtain
the length of the longest attribute name. The above program then
becomes:

  my $len = BSD::Process::attr_len;
  my $self = BSD::Process->new;
  for my $attr (BSD::Process::attr) {
    printf "%*s %s\n", $len, $attr, $self->{$attr};
  }

=item attr_alias

Returns the list of long aliases of the attributes.

=item max_kernel_groups

Returns the maximum number of groups to which a process may belong.
This is probably not of direct importance to the average Perl
programmer, but it eases calculating the number of regression tests
to be run in a cross-platform manner.

=back

=head1 METHODS

=over 4

=item refresh

Refreshes the information of a C<BSD::Process> object. For
instance, the following snippet shows a very accurate way
of measuring elapsed CPU time:

  my $proc  = BSD::Process->new;
  my $begin = $proc->runtime; # microseconds
  lengthy_calculation();

  $proc->refresh;
  my $elapsed = $proc->runtime - $begin;
  print "that took $elapsed microseconds of CPU time\n";

The method may be chained:

  my $runtime = $proc->refresh->runtime;

It may also be used with the C<P> shortcut.

  P; # to initialise
  lengthy_calculation();
  P->refresh;

=item resolve

Switches symbolic resolution on or off.

  my $proc = BSD::Process->new;
  print "$proc->{uid}\n";
  $proc->resolve;
  print "$proc->{uid}\n";

Note that changing the resolve setting will result in the
object being C<refresh>ed.

=back

=head1 PROCESS ATTRIBUTES

The following methods may be called on a C<BSD::Process> object.
Each process attribute may be accessed via two methods, a longer,
more descriptive name, or a terse name (following the member
name in the underlying C<kinfo_proc> C struct).

Furthermore, you may also interpolate the attribute (equivalent to
the terse method name) directly into a string. This can lead to
simpler code. The following three statements are equivalent:

  print "rss=", $p->resident_set_size;
  print "rss=", $p->rssize;
  print "rss=$p->{rssize};

A modification of a value in the underlying hash of the object
has no corresponding effect on the system process it represents.

Older kernels do not track as many process attributes as more
modern kernels. In these cases, the value -1 will be returned.

In the following list, the key B<F5+> means that the method
returns something useful in FreeBSD 5.x or better. The key
B<F6> means the method returns something useful for FreeBSD
6.x and beyond.

=over 4

=item process_args, args

The command with all its arguments as a string. When the process
args are unavailable, the name of the executable in brackets is
returned (same as in the F<ps> program). This may happen when the
length of the arguments exceeds the kernel limit set with the
C<kern.ps_arg_cache_limit> kernel setting. This is usually 256, for
more information check the manual page for the F<sysctl> program.

If you have the companion C<BSD::Sysctl> module installed, you can
check this with C<print sysctl("kern.ps_arg_cache_limit");> or else
with the C<sysctl(8)> command.

=item process_pid, pid

The identifier that identifies a process in a unique manner. No two
process share the same pid (process id).

=item parent_pid, ppid

The pid of the parent process that spawned the current process.
Many processes may share the same parent pid. Processes whose parents
exit before they do are reparented to init (pid 1).

=item process_group_id, pgid

A number of processes may belong to the same group (for instance,
all the processes in a shell pipeline). In this case they share the
same pgid.

=item tty_process_group_id, tpgid

Similarly, a number of processes belong to the same tty process
group. This means that they were all originated from the same console
login session or terminal window. B<F5+>

=item process_session_id, sid

Processes also belong to a session, identified by the process session
id. B<F5+>

=item terminal_session_id, tsid

A process that has belongs to a tty process group will also have a
terminal session id.

=item job_control_counter, jobc

The job control counter of a process. (purpose?) B<F5+>

=item effective_user_id, uid

The user id under which the process is running. A program with the
setuid bit set can be launched by any user, and the effective user
id will be that of the program itself, rather than that of the user.

The symbolic name of the uid will be returned if the constructor
had the C<resolve> attribute set. B<F5+>

=item real_user_id, ruid

The user id of the user that launched the process. B<F5+>

=item saved_effective_user_id, svuid

The saved effective user id of the process. (purpose?) B<F5+>

=item real_group_id, rgid

The primary group id of the user that launched the process.

The symbolic name of the gid will be returned if the constructor
had the C<resolve> attribute set. B<F5+>

=item saved_effective_group_id, svgid

The saved effective group id of the process. (purpose?) B<F5+>

=item number_of_groups, ngroups

The number of groups to which the process belongs. B<F5+>

=item group_list, groups

A reference to an array of group ids (gids) to which the process belongs. B<F5+>

=item virtual_size, size

The size (in bytes) of virtual memory occupied by the process. B<F5+>

=item resident_set_size, rssize

The size (in kilobytes) of physical memory occupied by the process.

=item rssize_before_swap, swrss

The resident set size of the process before the last swap.

=item text_size, tsize

Text size (in pages) of the process.

=item data_size, dsize

Data size (in pages) of the process. B<F5+>

=item stack_size, ssize

Stack size (in pages) of the process. B<F5+>

=item exit_status, xstat

Exit status of the process (usually zero).

=item accounting_flags, acflag

Process accounting flags (TODO: decode them).

=item percent_cpu, pctcpu

Percentage of CPU time used by the process (for the duration of
swtime, see below).

=item estimated_cpu, estcpu

Time averaged value of ki_cpticks. (as per the comment in user.h,
purpose?)

=item sleep_time, slptime

Number of seconds since the process was last blocked.

=item time_last_swap, swtime

Number of seconds since the process was last swapped in or out.

=item elapsed_time, runtime

Real time used by the process, in microseconds.

=item start_time, start

Epoch time of the creation of the process. B<F5+>

=item children_time, childtime

Amount of real time used by the children processes (if any) of the
process. B<F5+>

=item process_flags, flag

A bitmap of process flags (decoded in the following methods as 0
or 1).

=item posix_advisory_lock, advlock

Flag indicating whether the process holds a POSIX advisory lock. B<F5+>

=item has_controlling_terminal, controlt

Flag indicating whether the process has a controlling terminal (if
true, the terminal session id is stored in the C<tsid> attribute). B<F5+>

=item is_kernel_thread, kthread

Flag indicating whether the process is a kernel thread. B<F5+>

=item no_loadavg_calc, noload

Flag indicating whether the process contributes to the load average
calculations of the system. B<F5+>

=item parent_waiting, ppwait

Flag indicating whether the parent is waiting for the process to
exit. B<F5+>

=item started_profiling, profil

Flag indicating whether the process has started profiling. B<F5+>

=item stopped_profiling, stopprof

Flag indicating whether the process has a thread that has requesting
profiling to stop. B<F5+>

=item process_had_threads, hadthreads

Flag indicating whether the process has had thresds. B<F6+>

=item id_privs_set, sugid

Flag indicating whether the process has set id privileges since
last exec. B<F5+>

=item system_process, system

Flag indicating whether the process is a system process. B<F5+>

=item single_exit_not_wait, single_exit

Flag indicating that threads that are suspended should exit, not
wait. B<F5+>

=item traced_by_debugger, traced

Flag indicating that the process is being traced by a debugger. B<F5+>

=item waited_on_by_other, waited

Flag indicating that another process is waiting for the process. B<F5+>

=item working_on_exiting, wexit

Flag indicating that the process is working on exiting. B<F5+>

=item process_called_exec, exec

Flag indicating that the process has called exec. B<F5+>

=item kernel_session_flag, kiflag

A bitmap described kernel session status of the process, described
via the following attributes. B<F5+>

=item is_locked, locked

Flag indicating that the process is waiting on a lock (whose name
may be obtained from the C<lock> attribute). B<F5+>

  if ($p->is_locked) {
    print "$p->{comm} is waiting on lock $p->{lockname}\n";
  }
  else {
    print "not waiting on a lock\n";
  }

=item controlling_tty_active, isctty

Flag indicating that the vnode of the controlling tty is active. B<F5+>

=item is_session_leader, issleader

Flag indicating that the process is a session leader. B<F5+>

=item process_status, stat

Numeric value indicating the status of the process, decoded via the
following attibutes. B<F5+>

=item is_being_forked, stat_1

Status indicates that the process is being forked. B<F5+>

=item is_runnable, stat_2

Status indicates the process is runnable. B<F5+>

=item is_sleeping_on_addr, stat_3

Status indicates the process is sleeping on an address. B<F5+>

=item is_stopped, stat_4

Status indicates the process is stopped, either suspended or in a
debugger. B<F5+>

=item is_a_zombie, stat_5

Status indicates the process is a zombie. It is waiting for its
parent to collect its exit code. B<F5+>

=item is_waiting_on_intr, stat_6

Status indicates the process is waiting for an interrupt. B<F5+>

=item is_blocked, stat_7

Status indicates the process is blocked by a lock. B<F5+>

=item nice_priority, nice

The nice value of the process. The more positive the value, the
nicer the process (that is, the less it seeks to sit on the CPU).

=item process_lock_count, lock

Process lock count. If locked, swapping is prevented.

=item run_queue_index, rqindex

When multiple processes are runnable, the run queue index shows the
order in which the processes will be scheduled to run on the CPU.

=item current_cpu, oncpu

Identifies which CPU the process is running on.

=item last_cpu, lastcpu

Identifies the last CPU on which the process was running.

=item old_command_name, ocomm

The old command name. B<F5+>

=item wchan_message, wmesg

wchan message. (purpose?)

=item setlogin_name, login

Name of the user login process that launched the command.

=item name_of_lock, lockname

Name of the lock that the process is waiting on (if the process is
waiting on a lock). B<F5+>

=item command_name, comm

Name of the command.

=item emulation_name, emul

Name of the emulation. B<F6+>

=item process_jail_id, jid

The process jail identifier B<F6+>

=item number_of_threads, numthreads

Number of threads in the process. B<F6+>

=item priority_scheduling_class, pri_class

=item priority_level, pri_level

=item priority_native, pri_native

=item priority_user, pri_user

The parameters pertaining to the scheduling of the process. B<F6+>

=item user_time, utime

Process resource usage information. The amount of time spent by the
process in userland. B<F5+>

=item system_time, stime

Process resource usage information. The amount of time spent by the
process in the kernel (system calls). B<F5+>

=item total_time, time

The sum of the user and system times of the process.

Process resource usage information. The amount of time spent by the
process in the kernel (system calls). B<F5+>

=item max_resident_set_size, maxrss

Process resource usage information. The maximum resident set size
(the high-water mark of physical memory used) of the process. B<F5+>

=item shared_memory_size, ixrss

Process resource usage information. The size of shared memory. B<F5+>

=item unshared_data_size, idrss

Process resource usage information. The size of unshared memory. B<F5+>

=item unshared_stack_size, isrss

Process resource usage information. The size of unshared stack. B<F5+>

=item page_reclaims, minflt

Process resource usage information. Minor page faults, the number
of page reclaims. B<F5+>

=item page_faults, majflt

Process resource usage information. Major page faults, the number
of page faults. B<F5+>

=item number_of_swaps, nswap

Process resource usage information. The number of swaps the
process has undergone. B<F5+>

=item block_input_ops, inblock

Process resource usage information. Total number of input block
operations performed by the process. B<F5+>

=item block_output_ops, oublock

Process resource usage information. Total number of output block
operations performed by the process. B<F5+>

=item messages_sent, msgsnd

Process resource usage information. Number of messages sent by
the process. B<F5+>

=item messages_received, msgrcv

Process resource usage information. Number of messages received by
the process. B<F5+>

=item signals_received, nsignals

Process resource usage information. Number of signals received by
the process. B<F5+>

=item voluntary_context_switch, nvcsw

Process resource usage information. Number of voluntary context
switches performed by the process. B<F5+>

=item involuntary_context_switch, nivcsw

Process resource usage information. Number of involuntary context
switches performed by the process. B<F5+>

=item user_time_ch, utime_ch

=item system_time_ch, stime_ch

=item total_time_ch, time_ch

=item max_resident_set_size_ch, maxrss_ch

=item shared_memory_size_ch, ixrss_ch

=item unshared_data_size_ch, idrss_ch

=item unshared_stack_size_ch, isrss_ch

=item page_reclaims_ch, minflt_ch

=item page_faults_ch, majflt_ch

=item number_of_swaps_ch, nswap_ch

=item block_input_ops_ch, inblock_ch

=item block_output_ops_ch, oublock_ch

=item messages_sent_ch, msgsnd_ch

=item messages_received_ch, msgrcv_ch

=item signals_received_ch, nsignals_ch

=item voluntary_context_switch_ch, nvcsw_ch

=item involuntary_context_switch_ch => nivcsw_ch

These attributes (only available in FreeBSD 6.x) store the resource
usage of the child processes spawned by this process. Currently,
the kernel only fills in the information for the the C<utime_ch>
and C<stime_ch> fields (and hence the C<time_ch> value is derived
from them).

In theory (and in practice as far as I can tell) C<time_ch> is
equal to C<childtime>.

=back

=head1 DIAGNOSTICS

B<kern.proc.pid is corrupt>: a "can't happen" error when
attempting to retrieve the information of a process. If this
occurs, I'd like to know how you managed it.

B<kvm error in all()/list()>: another "can't happen" error when
asking the system to return the information about a process.

B<kvm error in list(): proc size mismatch (nnn total, nnn chunks)>:
you have upgraded a system across major versions, for instance 4.x
to 5.x, but the published system header files belong to the previous
version.

=head1 NOTES

Currently, FreeBSD versions 4 through 8 are supported. Support for
NetBSD and OpenBSD may be added in future versions.

=head1 SEE ALSO

=over 4

=item L<BSD::Sysctl>

Read and write kernel variables. With these two modules, there
should be much less need for writing shell scripts that scrape
the output of ps(1) and sysctl(8).

=item L<Proc::ProcessTable>

Seems to be a fairly wide cross-platform module. Goes into
a fair amount of depth, but not as much as C<BSD::Process>
does in its own particular niche. Also, FreeBSD has moved
away from the F</proc> filesystem.

Definitely the module to use if you need to go
multi-platform.

=item L<Solaris::Procfs>

Information about processes on the Solaris platform. The
documentation indicates that it is not finished, however,
it does not appear to have been updated since 2003.

=item L<Win32::Process::Info>

Information about current processes on the Win32 platform.

=back

=head1 BUGS

Not all of the ps(1) keywords are implemented. At the worst,
this (currently) means that you could not rewrite it in Perl.
This may be addressed in a future release.

Please report all bugs at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BSD-Process|rt.cpan.org>

Make sure you include the output from the following two commands:

  perl -MBSD::Process -le 'print $BSD::Process::VERSION'
  perl -V

I also accept pull requests on Github. See
L<https://github.com/dland/BSD-Process>

=head1 ACKNOWLEDGEMENTS

The FreeBSD Ports team, for their work on keeping this module up
to date on the ports tree. Their efforts are greatly appreciated.

Thanks also to az5112 on Github (I've lost their name), who implemented
the C<args> method.

=head1 AUTHOR

David Landgren, copyright (C) 2006-2013. All rights reserved.

http://www.landgren.net/perl/

If you (find a) use this module, I'd love to hear about it. If you
want to be informed of updates, send me a note. You know my first
name, you know my domain. Can you guess my e-mail address?

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

'The Lusty Decadent Delights of Imperial Pompeii';


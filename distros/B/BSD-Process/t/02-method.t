# 02-method.t
# Method tests for BSD::Process
#
# Copyright (C) 2006-2007 David Landgren

use strict;
use Test::More;

use BSD::Process;

use Config;
my $RUNNING_ON_FREEBSD_4 = $Config{osvers} =~ /^4/;
my $RUNNING_ON_FREEBSD_5 = $Config{osvers} =~ /^5/;

plan tests => 242
    + BSD::Process::max_kernel_groups
    + scalar(BSD::Process::attr_alias);

{
    my $pi = BSD::Process->new();   # implicit pid
    my $pe = BSD::Process->new($$); # explicit pid

    is( $pi->{pid}, $pe->{pid}, 'attribute pid' );
    is( $pi->{sid}, $pe->{sid}, 'attribute sid' );
    is( $pi->{tsid}, $pe->{tsid}, 'attribute tsid' );

    is($pe->pid,         delete $pe->{pid},         'method pid' );
    is($pe->ppid,        delete $pe->{ppid},        'method ppid');
    is($pe->pgid,        delete $pe->{pgid},        'method pgid');
    is($pe->tpgid,       delete $pe->{tpgid},       'method tpgid');
    is($pe->sid,         delete $pe->{sid},         'method tpgid');
    is($pe->jobc,        delete $pe->{jobc},        'method jobc');
    is($pe->rssize,      delete $pe->{rssize},      'method rssize');
    is($pe->swrss,       delete $pe->{swrss},       'method swrss');
    is($pe->tsize,       delete $pe->{tsize},       'method tsize');
    is($pe->xstat,       delete $pe->{xstat},       'method xstat');
    is($pe->acflag,      delete $pe->{acflag},      'method acflag');
    is($pe->pctcpu,      delete $pe->{pctcpu},      'method pctcpu');
    is($pe->estcpu,      delete $pe->{estcpu},      'method estcpu');
    is($pe->slptime,     delete $pe->{slptime},     'method slptime');
    is($pe->swtime,      delete $pe->{swtime},      'method swtime');
    is($pe->runtime,     delete $pe->{runtime},     'method runtime');
    is($pe->flag,        delete $pe->{flag},        'method flag');
    is($pe->nice,        delete $pe->{nice},        'method nice');
    is($pe->lock,        delete $pe->{lock},        'method lock');
    is($pe->rqindex,     delete $pe->{rqindex},     'method rqindex');
    is($pe->oncpu,       delete $pe->{oncpu},       'method oncpu');
    is($pe->lastcpu,     delete $pe->{lastcpu},     'method lastcpu');
    is($pe->wmesg,       delete $pe->{wmesg},       'method wmesg');
    is($pe->login,       delete $pe->{login},       'method login');
    is($pe->comm,        delete $pe->{comm},        'method comm');

    my $ngroups;
    is($pe->args,        delete $pe->{args},        'method args' );
    is($pe->tsid,        delete $pe->{tsid},        'method tsid');
    is($pe->uid,         delete $pe->{uid},         'method uid');
    is($pe->ruid,        delete $pe->{ruid},        'method ruid');
    is($pe->svuid,       delete $pe->{svuid},       'method svuid');
    is($pe->rgid,        delete $pe->{rgid},        'method rgid');
    is($pe->svgid,       delete $pe->{svgid},       'method svgid');
    is($pe->ngroups,     $ngroups = delete $pe->{ngroups}, 'method ngroups');
    is($pe->size,        delete $pe->{size},        'method size');
    is($pe->dsize,       delete $pe->{dsize},       'method dsize');
    is($pe->ssize,       delete $pe->{ssize},       'method ssize');
    is($pe->start,       delete $pe->{start},       'method start');
    is($pe->childtime,   delete $pe->{childtime},   'method childtime');
    is($pe->advlock,     delete $pe->{advlock},     'method advlock');
    is($pe->controlt,    delete $pe->{controlt},    'method controlt');
    is($pe->kthread,     delete $pe->{kthread},     'method kthread');
    is($pe->noload,      delete $pe->{noload},      'method noload');
    is($pe->ppwait,      delete $pe->{ppwait},      'method ppwait');
    is($pe->profil,      delete $pe->{profil},      'method profil');
    is($pe->stopprof,    delete $pe->{stopprof},    'method stopprof');
    is($pe->sugid,       delete $pe->{sugid},       'method sugid');
    is($pe->system,      delete $pe->{system},      'method system');
    is($pe->single_exit, delete $pe->{single_exit}, 'method single_exit');
    is($pe->traced,      delete $pe->{traced},      'method traced');
    is($pe->waited,      delete $pe->{waited},      'method waited');
    is($pe->wexit,       delete $pe->{wexit},       'method wexit');
    is($pe->exec,        delete $pe->{exec},        'method exec');
    is($pe->kiflag,      delete $pe->{kiflag},      'method kiflag');
    is($pe->locked,      delete $pe->{locked},      'method locked');
    is($pe->isctty,      delete $pe->{isctty},      'method isctty');
    is($pe->issleader,   delete $pe->{issleader},   'method issleader');
    is($pe->stat,        delete $pe->{stat},        'method stat');
    is($pe->stat_1,      delete $pe->{stat_1},      'method stat_1');
    is($pe->stat_2,      delete $pe->{stat_2},      'method stat_2');
    is($pe->stat_3,      delete $pe->{stat_3},      'method stat_3');
    is($pe->stat_4,      delete $pe->{stat_4},      'method stat_4');
    is($pe->stat_5,      delete $pe->{stat_5},      'method stat_5');
    is($pe->stat_6,      delete $pe->{stat_6},      'method stat_6');
    is($pe->stat_7,      delete $pe->{stat_7},      'method stat_7');
    is($pe->ocomm,       delete $pe->{ocomm},       'method ocomm');
    is($pe->lockname,    delete $pe->{lockname},    'method lockname');
    is($pe->pri_class,   delete $pe->{pri_class},   'method pri_class');
    is($pe->pri_level,   delete $pe->{pri_level},   'method pri_level');
    is($pe->pri_native,  delete $pe->{pri_native},  'method pri_native');
    is($pe->pri_user,    delete $pe->{pri_user},    'method pri_user');
    is($pe->utime,       delete $pe->{utime},       'method utime');
    is($pe->stime,       delete $pe->{stime},       'method stime');
    is($pe->time,        delete $pe->{time},        'method time (utime+stime)');
    is($pe->maxrss,      delete $pe->{maxrss},      'method maxrss');
    is($pe->ixrss,       delete $pe->{ixrss},       'method ixrss');
    is($pe->idrss,       delete $pe->{idrss},       'method idrss');
    is($pe->isrss,       delete $pe->{isrss},       'method isrss');
    is($pe->minflt,      delete $pe->{minflt},      'method minflt');
    is($pe->majflt,      delete $pe->{majflt},      'method majflt');
    is($pe->nswap,       delete $pe->{nswap},       'method nswap');
    is($pe->inblock,     delete $pe->{inblock},     'method inblock');
    is($pe->oublock,     delete $pe->{oublock},     'method oublock');
    is($pe->msgsnd,      delete $pe->{msgsnd},      'method msgsnd');
    is($pe->msgrcv,      delete $pe->{msgrcv},      'method msgrcv');
    is($pe->nsignals,    delete $pe->{nsignals},    'method nsignals');
    is($pe->nvcsw,       delete $pe->{nvcsw},       'method nvcsw');
    is($pe->nivcsw,      delete $pe->{nivcsw},      'method nivcsw');

    my $grouplist = $pe->groups;
    delete $pe->{groups};
    ok( defined($grouplist), 'method groups' );
    is( ref($grouplist), 'ARRAY', q{... it's a list} );
    SKIP: {
        skip( "not supported on FreeBSD 4.x", 1 )
            if $RUNNING_ON_FREEBSD_4;
        is( scalar(@$grouplist), $ngroups, "... of the expected size" )
            or diag("grouplist = (@$grouplist)");
    }

    is($pe->hadthreads,  delete $pe->{hadthreads},  'method hadthreads');
    is($pe->emul,        delete $pe->{emul},        'method emul');
    is($pe->jid,         delete $pe->{jid},         'method jid');
    is($pe->numthreads,  delete $pe->{numthreads},  'method numthreads');
    is($pe->utime_ch,    delete $pe->{utime_ch},    'method utime_ch');
    is($pe->stime_ch,    delete $pe->{stime_ch},    'method stime_ch');
    is($pe->time_ch,     delete $pe->{time_ch},     'method time_ch (utime_ch+stime_ch');
    is($pe->maxrss_ch,   delete $pe->{maxrss_ch},   'method maxrss_ch');
    is($pe->ixrss_ch,    delete $pe->{ixrss_ch},    'method ixrss_ch');
    is($pe->idrss_ch,    delete $pe->{idrss_ch},    'method idrss_ch');
    is($pe->isrss_ch,    delete $pe->{isrss_ch},    'method isrss_ch');
    is($pe->minflt_ch,   delete $pe->{minflt_ch},   'method minflt_ch');
    is($pe->majflt_ch,   delete $pe->{majflt_ch},   'method majflt_ch');
    is($pe->nswap_ch,    delete $pe->{nswap_ch},    'method nswap_ch');
    is($pe->inblock_ch,  delete $pe->{inblock_ch},  'method inblock_ch');
    is($pe->oublock_ch,  delete $pe->{oublock_ch},  'method oublock_ch');
    is($pe->msgsnd_ch,   delete $pe->{msgsnd_ch},   'method msgsnd_ch');
    is($pe->msgrcv_ch,   delete $pe->{msgrcv_ch},   'method msgrcv_ch');
    is($pe->nsignals_ch, delete $pe->{nsignals_ch}, 'method nsignals_ch');
    is($pe->nvcsw_ch,    delete $pe->{nvcsw_ch},    'method nvcsw_ch');
    is($pe->nivcsw_ch,   delete $pe->{nivcsw_ch},   'method nivcsw_ch');
    # check for typos in hv_store calls in Process.xs
    is( scalar(grep {!/^_/} keys %$pe), 0, 'all methods have been accounted for' )
        or diag( 'leftover: ' . join( ',', grep {!/^_/} keys %$pe ));

    $pe->refresh;

    # longhand method names
    is($pe->process_pid,                   delete $pe->{pid},         'alias process_pid' );
    is($pe->parent_pid,                    delete $pe->{ppid},        'alias parent_pid');
    is($pe->process_group_id,              delete $pe->{pgid},        'alias process_group_id');
    is($pe->tty_process_group_id,          delete $pe->{tpgid},       'alias tty_process_group_id');
    is($pe->process_session_id,            delete $pe->{sid},         'alias tty_process_group_id');
    is($pe->job_control_counter,           delete $pe->{jobc},        'alias job_control_counter');
    is($pe->resident_set_size,             delete $pe->{rssize},      'alias resident_set_size');
    is($pe->rssize_before_swap,            delete $pe->{swrss},       'alias rssize_before_swap');
    is($pe->text_size,                     delete $pe->{tsize},       'alias text_size');
    is($pe->exit_status,                   delete $pe->{xstat},       'alias exit_status');
    is($pe->accounting_flags,              delete $pe->{acflag},      'alias accounting_flags');
    is($pe->percent_cpu,                   delete $pe->{pctcpu},      'alias percent_cpu');
    is($pe->estimated_cpu,                 delete $pe->{estcpu},      'alias estimated_cpu');
    is($pe->sleep_time,                    delete $pe->{slptime},     'alias sleep_time');
    is($pe->time_last_swap,                delete $pe->{swtime},      'alias time_last_swap');
    is($pe->elapsed_time,                  delete $pe->{runtime},     'alias elapsed_time');
    is($pe->process_flags,                 delete $pe->{flag},        'alias process_flags');
    is($pe->nice_priority,                 delete $pe->{nice},        'alias nice_priority');
    is($pe->process_lock_count,            delete $pe->{lock},        'alias process_lock_count');
    is($pe->run_queue_index,               delete $pe->{rqindex},     'alias run_queue_index');
    is($pe->current_cpu,                   delete $pe->{oncpu},       'alias current_cpu');
    is($pe->last_cpu,                      delete $pe->{lastcpu},     'alias last_cpu');
    is($pe->wchan_message,                 delete $pe->{wmesg},       'alias wchan_message');
    is($pe->setlogin_name,                 delete $pe->{login},       'alias setlogin_name');
    is($pe->command_name,                  delete $pe->{comm},        'alias command_name');

    is($pe->process_args,                  delete $pe->{args},        'alias process_args' );
    is($pe->terminal_session_id,           delete $pe->{tsid},        'alias terminal_session_id');
    is($pe->effective_user_id,             delete $pe->{uid},         'alias effective_user_id');
    is($pe->real_user_id,                  delete $pe->{ruid},        'alias real_user_id');
    is($pe->saved_effective_user_id,       delete $pe->{svuid},       'alias saved_effective_user_id');
    is($pe->real_group_id,                 delete $pe->{rgid},        'alias real_group_id');
    is($pe->saved_effective_group_id,      delete $pe->{svgid},       'alias saved_effective_group_id');
    is($pe->number_of_groups,              delete $pe->{ngroups},     'alias number_of_groups');
    is($pe->virtual_size,                  delete $pe->{size},        'alias virtual_size');
    is($pe->data_size,                     delete $pe->{dsize},       'alias data_size');
    is($pe->stack_size,                    delete $pe->{ssize},       'alias stack_size');
    is($pe->start_time,                    delete $pe->{start},       'alias start_time');
    is($pe->children_time,                 delete $pe->{childtime},   'alias children_time');
    is($pe->posix_advisory_lock,           delete $pe->{advlock},     'alias posix_advisory_lock');
    is($pe->has_controlling_terminal,      delete $pe->{controlt},    'alias has_controlling_terminal');
    is($pe->is_kernel_thread,              delete $pe->{kthread},     'alias is_kernel_thread');
    is($pe->no_loadavg_calc,               delete $pe->{noload},      'alias no_loadavg_calc');
    is($pe->parent_waiting,                delete $pe->{ppwait},      'alias parent_waiting');
    is($pe->started_profiling,             delete $pe->{profil},      'alias started_profiling');
    is($pe->stopped_profiling,             delete $pe->{stopprof},    'alias stopped_profiling');
    is($pe->id_privs_set,                  delete $pe->{sugid},       'alias id_privs_set');
    is($pe->system_process,                delete $pe->{system},      'alias system_process');
    is($pe->single_exit_not_wait,          delete $pe->{single_exit}, 'alias single_exit_not_wait');
    is($pe->traced_by_debugger,            delete $pe->{traced},      'alias traced_by_debugger');
    is($pe->waited_on_by_other,            delete $pe->{waited},      'alias waited_on_by_other');
    is($pe->working_on_exiting,            delete $pe->{wexit},       'alias working_on_exiting');
    is($pe->process_called_exec,           delete $pe->{exec},        'alias process_called_exec');
    is($pe->kernel_session_flag,           delete $pe->{kiflag},      'alias kernel_session_flag');
    is($pe->is_locked,                     delete $pe->{locked},      'alias is_locked');
    is($pe->controlling_tty_active,        delete $pe->{isctty},      'alias controlling_tty_active');
    is($pe->is_session_leader,             delete $pe->{issleader},   'alias is_session_leader');
    is($pe->process_status,                delete $pe->{stat},        'alias process_status');
    is($pe->is_being_forked,               delete $pe->{stat_1},      'alias is_being_forked');
    is($pe->is_runnable,                   delete $pe->{stat_2},      'alias is_runnable');
    is($pe->is_sleeping_on_addr,           delete $pe->{stat_3},      'alias is_sleeping_on_addr');
    is($pe->is_stopped,                    delete $pe->{stat_4},      'alias is_stopped');
    is($pe->is_a_zombie,                   delete $pe->{stat_5},      'alias is_a_zombie');
    is($pe->is_waiting_on_intr,            delete $pe->{stat_6},      'alias is_waiting_on_intr');
    is($pe->is_blocked,                    delete $pe->{stat_7},      'alias is_blocked');
    is($pe->old_command_name,              delete $pe->{ocomm},       'alias old_command_name');
    is($pe->name_of_lock,                  delete $pe->{lockname},    'alias name_of_lock');
    is($pe->priority_scheduling_class,     delete $pe->{pri_class},   'alias priority_scheduling_class');
    is($pe->priority_level,                delete $pe->{pri_level},   'alias priority_level');
    is($pe->priority_native,               delete $pe->{pri_native},  'alias priority_native');
    is($pe->priority_user,                 delete $pe->{pri_user},    'alias priority_user');
    is($pe->user_time,                     delete $pe->{utime},       'alias user_time');
    is($pe->system_time,                   delete $pe->{stime},       'alias system_time');
    is($pe->total_time,                    delete $pe->{time},        'alias total_time');
    is($pe->max_resident_set_size,         delete $pe->{maxrss},      'alias max_resident_set_size');
    is($pe->shared_memory_size,            delete $pe->{ixrss},       'alias shared_memory_size');
    is($pe->unshared_data_size,            delete $pe->{idrss},       'alias unshared_data_size');
    is($pe->unshared_stack_size,           delete $pe->{isrss},       'alias unshared_stack_size');
    is($pe->page_reclaims,                 delete $pe->{minflt},      'alias page_reclaims');
    is($pe->page_faults,                   delete $pe->{majflt},      'alias page_faults');
    is($pe->number_of_swaps,               delete $pe->{nswap},       'alias number_of_swaps');
    is($pe->block_input_ops,               delete $pe->{inblock},     'alias block_input_ops');
    is($pe->block_output_ops,              delete $pe->{oublock},     'alias block_output_ops');
    is($pe->messages_sent,                 delete $pe->{msgsnd},      'alias messages_sent');
    is($pe->messages_received,             delete $pe->{msgrcv},      'alias messages_received');
    is($pe->signals_received,              delete $pe->{nsignals},    'alias signals_received');
    is($pe->voluntary_context_switch,      delete $pe->{nvcsw},       'alias voluntary_context_switch');
    is($pe->involuntary_context_switch,    delete $pe->{nivcsw},      'alias involuntary_context_switch');
    is($pe->process_had_threads,           delete $pe->{hadthreads},  'alias process_had_threads');
    is($pe->emulation_name,                delete $pe->{emul},        'alias emulation_name');
    is($pe->process_jail_id,               delete $pe->{jid},         'alias process_jail_id');
    is($pe->number_of_threads,             delete $pe->{numthreads},  'alias number_of_threads');
    is($pe->user_time_ch,                  delete $pe->{utime_ch},    'alias user_time');
    is($pe->system_time_ch,                delete $pe->{stime_ch},    'alias system_time');
    is($pe->total_time_ch,                 delete $pe->{time_ch},     'alias total_time');
    is($pe->max_resident_set_size_ch,      delete $pe->{maxrss_ch},   'alias max_resident_set_size');
    is($pe->shared_memory_size_ch,         delete $pe->{ixrss_ch},    'alias shared_memory_size');
    is($pe->unshared_data_size_ch,         delete $pe->{idrss_ch},    'alias unshared_data_size');
    is($pe->unshared_stack_size_ch,        delete $pe->{isrss_ch},    'alias unshared_stack_size');
    is($pe->page_reclaims_ch,              delete $pe->{minflt_ch},   'alias page_reclaims');
    is($pe->page_faults_ch,                delete $pe->{majflt_ch},   'alias page_faults');
    is($pe->number_of_swaps_ch,            delete $pe->{nswap_ch},    'alias number_of_swaps');
    is($pe->block_input_ops_ch,            delete $pe->{inblock_ch},  'alias block_input_ops');
    is($pe->block_output_ops_ch,           delete $pe->{oublock_ch},  'alias block_output_ops');
    is($pe->messages_sent_ch,              delete $pe->{msgsnd_ch},   'alias messages_sent');
    is($pe->messages_received_ch,          delete $pe->{msgrcv_ch},   'alias messages_received');
    is($pe->signals_received_ch,           delete $pe->{nsignals_ch}, 'alias signals_received');
    is($pe->voluntary_context_switch_ch,   delete $pe->{nvcsw_ch},    'alias voluntary_context_switch');
    is($pe->involuntary_context_switch_ch, delete $pe->{nivcsw_ch},   'alias involuntary_context_switch');

    $grouplist = $pe->group_list;
    delete $pe->{groups};
    SKIP: {
        skip( "not supported on FreeBSD 4.x", 3 )
            if $RUNNING_ON_FREEBSD_4;
        ok( defined($grouplist), 'alias group_list' );
        is( ref($grouplist), 'ARRAY', q{... it's also a list} );
        SKIP: {
            skip( "didn't get an ARRAY in previous test", 1 )
                unless ref($grouplist);
            is( scalar(@$grouplist), $ngroups, "... also of the expected size" )
                or diag("grouplist = (@$grouplist)");
        }
    }

    # check for typos in hv_store calls in Process.xs
    is( scalar(grep {!/^_/} keys %$pe), 0, 'all aliases have been accounted for' )
        or diag( 'leftover: ' . join( ',', grep {!/^_/} keys %$pe ));

    my $time = $pi->runtime;
    cmp_ok( $pi->refresh->runtime, '>', $time, 'refresh updates counters' );

    $pe->refresh;
    for my $method (sort {$a cmp $b} BSD::Process::attr_alias) {
        ok($pe->can($method), "can $method");
    }
}

{
    # check symbolic uids and gids
    my $num = BSD::Process->new();
    my $sym_imp = BSD::Process->new(     {resolve => 1} );
    my $sym_exp = BSD::Process->new( $$, {resolve => 1} );

    my $num_grouplist = $num->groups;
    my $sym_grouplist = $sym_imp->group_list;

    SKIP: {
        skip( "not supported on FreeBSD 4.x", 13 )
            if $RUNNING_ON_FREEBSD_4;
        is( $num->uid,   scalar(getpwnam($sym_imp->uid)),   'implicit pid resolve muid' );
        is( $num->ruid,  scalar(getpwnam($sym_imp->ruid)),  'implicit pid resolve ruid' );
        is( $num->svuid, scalar(getpwnam($sym_imp->svuid)), 'implicit pid resolve svuid' );
        is( $num->rgid,  scalar(getgrnam($sym_imp->rgid)),  'implicit pid resolve rgid' );
        is( $num->svgid, scalar(getgrnam($sym_imp->svgid)), 'implicit pid resolve svgid' );

        is( $num->uid,   scalar(getpwnam($sym_exp->uid)),   'explicit pid resolve uid' );
        is( $num->ruid,  scalar(getpwnam($sym_exp->ruid)),  'explicit pid resolve ruid' );
        is( $num->svuid, scalar(getpwnam($sym_exp->svuid)), 'explicit pid resolve svuid' );
        is( $num->rgid,  scalar(getgrnam($sym_exp->rgid)),  'explicit pid resolve rgid' );
        is( $num->svgid, scalar(getgrnam($sym_exp->svgid)), 'explicit pid resolve svgid' );

        is( ref($num_grouplist), 'ARRAY', 'numeric grouplist is an ARRAY' );
        is( ref($sym_grouplist), 'ARRAY', 'symbolic grouplist is an ARRAY' );

        is( scalar(@$num_grouplist), scalar(@$sym_grouplist), 'groups counts' );
    }

    for my $gid (0..BSD::Process::max_kernel_groups) {
        if ($gid < @$num_grouplist) {
            is( $num_grouplist->[$gid],  scalar(getgrnam($sym_grouplist->[$gid])), "resolve group $gid" );
        }
        else {
            pass( "resolve group $gid (none on this platform)" );
        }
    }
}

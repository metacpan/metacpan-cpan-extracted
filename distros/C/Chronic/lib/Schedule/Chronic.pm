#
# Constraint-based, opportunistic scheduler.
# Author: Vipul Ved Prakash <mail@vipul.net>.
# $Id: Chronic.pm,v 1.14 2005/04/26 07:25:34 hackworth Exp $
#

package Schedule::Chronic; 
use base qw(Schedule::Chronic::Base Schedule::Chronic::Tab);
use Schedule::Chronic::Timer;
use Schedule::Chronic::Logger;
use Data::Dumper;


sub new { 

    my ($class, %args) = @_;
    my %self = (%args);

    $self{safe_sleep}           ||= 1;      # 1 second
    $self{scheduler_wait}       = new Schedule::Chronic::Timer ('down');
    $self{var}                  ||= '/var/run';
    $self{max_sw}               = 10 * 60;  # 10 minutes
    $self{only_once_tw}         = 10 * 365 * 24 * 3600; # 10 years
    $self{logger}               = new Schedule::Chronic::Logger (type => $args{logtype});
    $self{nohup}                = 0;
    $self{pending_hup}          = 0;

    unless (exists $self{debug}) {
        $self{debug} = 1;
    }

    return bless \%self, $class;

}


sub load_cns_for_schedule { 

    my ($self) = @_;

    for my $task (@{$$self{_schedule}}) { 
        unless (exists $task->{_sched_constraints_loaded}) { 
            $self->load_cns_for_task($task);
        } 
    }

}


sub load_cns_for_task { 

    my ($self, $task) = @_;

    my $constraints = $task->{constraints};
    my $n_objects = 0;

    my $prep_args = sub { 

        my $topass = Dumper shift;
        $topass =~ s/\$VAR1 = \[//; 
        $topass =~ s/];\s*//g; 
        return $topass;

    };

    for my $constraint (keys %$constraints) { 

        # Load the module corresponding to the constraint from
        # disk. Die with a FATAL error if the module is not
        # loaded. This behaviour should be configurable through
        # a data member.

        my $module = "Schedule::Chronic::Constraint::$constraint";
        eval "require $module; use $module";
        if ($@) { 
            my $error = join'', $@;
            if ($error =~ m"Can't locate (\S+)") { 
               $self->fatal("Cant' locate constraint module ``$1''");
            }
        }

        # Call the constructor and then the init() method to
        # pass the constraint object a copy of schedule, task
        # and thresholds/parameters supplied by the user. Save
        # the constraint object under the constraint key.

        my $constructor = "$module->new()";
        $task->{constraints}->{$constraint}->{_object} = eval $constructor or die $!;
        my $object = $task->{constraints}->{$constraint}->{_object};

        my $init = $object->init (
             $$self{_schedule}, $task, $$self{logger},
                @{$task->{constraints}->{$constraint}->{thresholds}}
        );

        unless ($init) { 
            $self->fatal("init() failed for $module")
        }

        $n_objects++;

    }

    # All's good.
    $self->debug("$n_objects constraint objects created.");
    $task->{_sched_constraints_loaded} = 1;
    # print Dumper $self;

    return 1;

}
        

sub schedule { 

    my $self = shift;

    my $schedule = $$self{_schedule};
    my $scheduler_wait = $$self{scheduler_wait};

    # A subroutine to compute a scheduler wait, which is the the
    # smallest of all task waits. We call this routine after
    # we've run through all tasks at least once. This function
    # is closed under schedule() so it has access to variables
    # local to schedule.

    my $recompute_scheduler_wait = sub { 

        unless (scalar @{$schedule}) { 

            # Oops, there are no tasks. We'll set wait to
            # maximum and hope that tasks show up the next time
            # this function is called.

            $self->debug("no tasks to schedule.");
            $scheduler_wait->set($$self{max_sw});
            $self->debug("scheduler_wait: set to " . $self->time_rd($$self{max_sw}));
            return;

        }

        my $sw = $schedule->[0]->{_task_wait}->get();

        for my $task (@$schedule) { 
            if ($$task{_task_wait}->get() < $sw) {
                $sw = $$task{_task_wait}->get();;
            }
        }

        $sw = $self->{max_sw} if $sw > $self->{max_sw};

        if ($sw > 0) { 
            $scheduler_wait->set($sw);
            $self->debug("scheduler_wait: set to " . $self->time_rd($sw));
        }

    };
 
    $self->debug("entering scheduler loop...");

    while (1) { 

        # Check to see if scheduler_wait is positive.  If so, 
        # go to sleep because all task waits are larger than 
        # scheduler_wait.

        if ($scheduler_wait->get() > 0) { 
            $self->debug("nothing to schedule for " . 
                $self->time_rd($scheduler_wait->get()) . ", sleeping...");
            sleep($scheduler_wait->get());
        }

        # Walk over all tasks, checks constraints and execute tasks when
        # all constraints are met. This is section should end in

        TASK: 
        for my $task (@$schedule) {

            # print Dumper $task; 

            # A task has four components. A set of constraints, a
            # command to run when these constraints are met, the
            # last_ran time and a task wait timer which is the
            # maximum wait time returned by a constraint.

            my $constraints = $$task{constraints};
            my $task_wait   = $$task{_task_wait};
            my $command     = $$task{command};
            my $last_ran    = $$task{last_ran};
            my $uid         = $$task{_uid};
            my $only_once   = $$task{only_once};

            if ($last_ran > 0 and $only_once == 1) { 

                # This task was supposed to run ``only_once'' and it has
                # been run once before, so we will skip it.

                $task_wait->set($$self{only_once_tw});
                next TASK;

            }

            $self->debug("* $command");

            if ($task_wait->get() > 0) { 

                # Constraints have indicated that they will not be met for
                # at least sched_wait seconds.

                $self->debug("  task_wait: " . $self->time_rd($task_wait->get()));
                next TASK;

            };

            my $all_cns_met = 1;

            for my $constraint (keys %$constraints) { 

                # A constraint has two declarative components and a few
                # derived components. The declarative components are the
                # name of the constraint and the thresholds that
                # parameterize the constraint. The derived components
                # include the corresponding constraint object and other
                # transient data structures used by the scheduler.

                my $cobject = $task->{constraints}->{$constraint}->{_object};

                # Now call met() and wait()

                my ($met)  = $cobject->met();
                my ($wait) = $cobject->wait();

                if (not $met) { 

                    # The constraint wasn't met. We'll set all_cns_met to
                    # 0 and compare constraint wait with task_wait to see
                    # if we need to readjust task_wait.

                    $self->debug("  ($constraint) unmet");
                    $all_cns_met = 0;

                    if ($wait != 0 && $wait > $task_wait->get()) { 

                        # Task wait is largest of all constraint waits.

                        $self->debug("  ($constraint) won't be met for " . $self->time_rd($wait));
                        $task_wait->set($wait);

                    }

                } else { 
 
                    # The constraint has been met. Add a log notification.
                    # We don't need to do anything. If all constraints are
                    # met, all_cns_set will remain set to 1.

                    $self->debug("  ($constraint) met");
                   
                }

            } # for - iterate over constraints

            if ($all_cns_met) { 

                # All constraints met: the task is ready to run.

                # Set nohup to 1. Tells the SIGNAL handler that
                # this is not a good time for a HUP. If we
                # receive a HUP during system(), the handler
                # will record this in $self->{pending_hup} so we
                # can replay the signal after system() is done.

                $self->{nohup} = 1;

                my $now = time();
                $$task{_previous_run} = $now - $$task{last_ran};
                $$task{last_ran} = $now;
                my $rv = system($$task{command});
                $$task{_last_rv} = $rv;

                # Write the chrontab with updated last_ran value for the
                # task only if the task is not an ``only_once'' task.

                $self->write_chrontab($$task{_chrontab});
               
                # Notify the email address.
                if ($$task{notify}) { 
                    $self->notify($task, time() - $$task{last_ran});
                }

                $self->{nohup} = 0;
                if ($self->{pending_hup}) { 

                    # If there got a HUP during system();
                    # replay it now.

                    $self->debug("replaying HUP signal sent earlier");
                    kill(1, $$self{pid});
                }
                
            }
    
        } # for - iterate over tasks

        # Compute the schedular wait before going through the next
        # cycle. Scheduler wait is set only if the largest
        # task_wait is > 0.

        &$recompute_scheduler_wait();

        # We'll do a one second sleep here so we don't cycle out
        # of control when there's a mismatch between task_wait's
        # and the scheduler_wait.

        sleep ($self->{safe_sleep});

    } # while - scheduler loop

}


sub getpid { 

    my ($self) = @_;
    $self->{pid} = $$;

}


sub notify { 

    my ($self, $task, $time) = @_;

    # Sometimes /usr/lib won't be in path, so we look there first before
    # calling which()

    my $success = $$task{_last_rv} == 0 ? 1 : 0;

    my $sendmail_path = '/usr/lib/sendmail';
    unless (-e $sendmail_path) { 
        $sendmail_path = $self->which('sendmail');
    } 

    unless ($sendmail_path) { 
        $self->debug("``sendmail'' not found, can't notify");
        return;
    }

    $self->debug("  sending notification to $$task{notify}");

    my $template; 

    # Headers

    $template .= "From: chronic\@localhost\n"; # FIX. username@host
    $template .= "To: $$task{notify}\n";
    $template .= "Subject: [Chronic] Success: $$task{command}\n\n" if $success;
    $template .= "Subject: [Chronic] Failure: $$task{command}\n\n" unless $success;

    # Body

    $template .= "Task executed successfully.\n\n" if $success;
    $template .= "\nTask failed.\n\n" unless $success;
    $template .= sprintf("%20s: %s\n", "Task", $$task{command});
    $template .= sprintf("%20s: %s\n", "Executed at", scalar localtime());
    $template .= sprintf("%20s: %s\n", "Run time", $self->time_rd($time) . ".");
    $template .= sprintf("%20s: %s\n", "Return Value", $$task{_last_rv});
    $template .= sprintf("%20s: %s\n", "UID", $$task{_uid});
    $template .= sprintf("%20s: %s\n", "Previous run", $self->time_rd($$task{_previous_run}) . " ago.")
            if exists $$task{_previous_run} and $$task{only_once} == 0;
    $template .= "\nThis was an ``only_once'' task.  It won't be rescheduled.\n" if $$task{only_once};
    $template .= "\nVirtually yours,\nChronic\n";

    open(SENDMAIL, "| $sendmail_path $$task{notify}");
    print SENDMAIL $template; 
    print SENDMAIL ".\n";
    
    close SENDMAIL;

    return $self;

}


sub time_rd { 

    my ($self, $seconds) = @_;

    if ($seconds > 3600) { 
        my $hours = $seconds / 3600;
        if ($hours > 24) { 
            return sprintf("%.2f days", $hours/24);
        } else { 
            return sprintf("%.2f hours", $hours);
        }
    } elsif ($seconds > 60) { 
        return sprintf("%.1f minutes", $seconds/60);
    } 

    return "$seconds seconds";

}


1;


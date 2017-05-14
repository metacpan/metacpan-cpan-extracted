##
## Serialize schedule to chrontab and vice versa.
## Author: Vipul Ved Prakash <mail@vipul.net>.
## $Id: Tab.pm,v 1.10 2004/06/30 21:50:38 hackworth Exp $
## 


package Schedule::Chronic::Tab;
use English;


sub read_tabs { 

    my ($self, $tab) = @_;

    if ($tab) { 

        # Read the specified chrontab
        $self->read_chrontab($tab, $UID);
        return $self;

    }
    
    # A chrontab was not specified so we will find all
    # appropriate chrontabs and load 'em up.

    if ($UID == 0) {         

        # If the user is root, look for /etc/chrontab and then
        # all user specific chrontabs.

        if (-e '/etc/chrontab') { 
            $self->read_chrontab('/etc/chrontab', 0);
        } else { 
            $self->fatal("No chrontabs found.  Was exepecting one in /etc/chrontab.");
        }

        # To look for user specific chrontabs, we need to walk
        # over all the users in /etc/passwd and search for
        # $HOME/.chrontab under their user directories. We also
        # need to discover their UIDs. All this information is
        # available in /etc/passwd.
        #
        # FIX!

    }  else { 

        # The user is not root, we'll look for $HOME/.chrontab

        my $tab = "$ENV{HOME}/.chrontab";

        if (-e $tab) { 
    
            $self->read_chrontab($tab, $UID);

        } else { 

            $self->fatal("No chrontabs found.  Was expecting one in $tab.");

        }

    }


}


sub read_chrontab { 

    my ($self, $tab, $uid) = @_;

    open TAB, $tab or die "$tab: $!";
    $self->debug("reading chrontab ``$tab''..."); 

    # A function to remove leading and trailing spaces from tokens. 
    my $normalize = sub { $_ = shift; return unless $_; s/^\s+//; s/\s+$//; return $_; };

    # Test vectors: 
    #
    # 1. command = "/usr/bin/updatedb"; constraint = Inactivity, 600;
    # 2. command = "/usr/bin/emerge rsync"; \ 
    #       constraint = DiskIO, 600; contraint = Loadavg, 600, 0.05;
    # 3. command = "/usr/bin/emerge rsync"; \ 
    #       constraint = DiskIO, 600; contraint = Loadavg, 600, 0.05; \ 
    #       last_ran = 1082709815;

    my $last_entry = '';  # To keep track of continuations
    my $tasks = 0;
    my $linecursor = 0;

    while ($_ = <TAB>) { 

        $linecursor++;
        next unless /\S/;
        next if /^\s*#/;
        chomp;

        my $entry = $normalize->($_);

        if ($entry =~ m|\\$|) { 

            # This is a continuation, save in $last_entry 
            # so it can be concatenated.

            $last_entry .= $entry;
            $last_entry =~ s|\\$||; 
            next;

        } elsif ($last_entry) { 

            # If there's a continuation, roll it in, and 
            # set $last_entry to empty string.

            $entry = "$last_entry $entry";
            $last_entry = '';

        }

        my %task;
        my @pairs = split /;/, $entry;
        my $good = 0;  # track is this is a good pair

        for (@pairs) { 

            # Extract key = value; pairs
            my ($key, $value) = split /=/, $_, 2;

            # Normalize key and value 
            $key = $normalize->($key);
            $value = $normalize->($value);
            next unless $key and $value;

            $good = 1;

            if ($key eq 'command') { 

                # Remove quotes from the command
                $value =~ s/^"//;
                $value =~ s/"$//;
                $task{$key} = $value;

            } elsif ($key eq 'constraint') { 

                # A constraint contains a constrain name followed by an
                # optional list of parameters for the constraint. 

                my ($constraint, @thresholds) = split /,/, $value;

                my @n_thresholds;
                $constraint = $normalize->($constraint);
                for (@thresholds) { 
                    push @n_thresholds, $normalize->($_);
                }
                    
                $task{constraints}->{$constraint} = {};
                $task{constraints}->{$constraint}{thresholds} = [@n_thresholds] if 
                    scalar @n_thresholds;
            }

            else { 

                # All other keys are read in verbatim.
                $task{$key} = $value;
    
            }

        }

        # If there's no command, this task is useless to us.
        $good = 0 unless exists $task{command};

        if ($good) { 

            # Initialize the task.
            # 
            # Add a last_ran of 0 (execute soon as possible)
            # if a last_ran is not available. Create a 
            # task_wait timer and initialize other task 
            # parameters.

            $task{last_ran} = 0 unless exists $task{last_ran};
            $task{only_once} = 0 unless exists $task{only_once};
            $task{_task_wait} = new Schedule::Chronic::Timer ('down');
            $task{_task_wait}->set(0);
            $task{_uid} = $uid;
            $task{_chrontab} = $tab;
            $task{_last_rv} = 0;

            push @{$self->{_schedule}}, {%task};
            $tasks++;

        } else { 

            # This entry is b0rken. Show it to the user.
            # We should probably barf here and ask the user
            # to correct the error. FIX.

            $self->debug("Syntax error in line $linecursor of $tab - ignoring.");

        }

    }

    $self->debug("$tasks task(s) loaded.");

    close TAB;

}


sub write_chrontab { 

    my ($self, $tab) = @_;
    open TAB, ">$tab" or die "$tab: $!\n";

    # Walk over the _schedule and write all tasks to the config
    # file. This essentially serializes the _schedule in a format
    # as close as the original file as possible.

    for (@{$self->{_schedule}}) {

        my $task = $_;

        unless ($$task{_chrontab} eq $tab) { 

            # This task belongs to another chrontab, 
            # skip over it.

            next;

        }

        if ($$task{only_once} == 1 and $$task{last_ran} > 0) { 

            # This was an ``only_once'' task that has been
            # executed once. Don't write back to the 
            # chrontab.

            next;

        }

        for my $key (keys %$task) {

            if ($key eq 'command') { 
                
                # Quote the command before writing it to disk.
                print TAB "$key = \"$task->{$key}\"; ";

            } elsif ($key eq 'constraints') { 

                # Serialize the constraint. Format is:
                #`` constraint = name, thresholds''
                # where thresholds is a comma separated list.
                
                my $constraints_set = $task->{constraints};

                for (keys %$constraints_set) { 

                    print TAB "constraint = $_";

                    if (exists $constraints_set->{$_}->{thresholds}) { 
                        $" = ", "; print TAB ", ";
                        print TAB "@{$constraints_set->{$_}->{thresholds}}";
                    }

                    print TAB "; ";

                }

            # All verbatim fields go here.

            } elsif ($key eq 'last_ran' or $key eq 'notify' or $key eq 'only_once') { 

                unless ($key eq 'only_once' and $task->{$key} == 0) { 
                    print TAB "$key = $task->{$key}; ";
                }

            } else { 

                # Unrecognized key, which is used for the 
                # internal data structures.

                next;

            }

        }
    
        print TAB "\n";

    }

    $self->debug("wrote $tab");

    close TAB;

}
 

1;


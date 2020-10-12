#!/usr/bin/perl -w

use strict;

use lib ('./blib','../blib','../lib','./lib');
use Class::NamedParms;

$| = 1;

my @do_tests=(1..8);

my $test_subs = { 
       1 => { -code => \&test_set,                     -desc => 'set                    ' },
       2 => { -code => \&test_get,                     -desc => 'get                    ' },
       3 => { -code => \&test_clear,                   -desc => 'clear                  ' },
       4 => { -code => \&test_undeclare,               -desc => 'undeclare              ' },
       5 => { -code => \&test_list_declared_parms,     -desc => 'list_declared_parms    ' },
       6 => { -code => \&test_list_initialized_parms,  -desc => 'list_initialized_parms ' },
       7 => { -code => \&test_all_parms,               -desc => 'all_parms              ' },
       8 => { -code => \&test_exists,                  -desc => 'exists                 ' },
};
run_tests($test_subs);

exit;

###########################################################################
###########################################################################

########################################
# set                                  #
########################################
sub test_set {
    eval {
        my $class = legacy_instance(-testing);
        $class->set;
    };
    if ($@) {
        return "setting parameter using null list failed: $@";
    }

    eval {
        my $class = legacy_instance(-testing);
        $class->set({ -testing => 1 });
    };
    if ($@) {
        return "setting parameter via anon hash ref failed: $@";
    }

    eval {
        my $class = legacy_instance(-testing);
        $class->set( -testing => 1 );
    };
    if ($@) {
        return "setting parameter via straight list failed: $@";
    }
    eval {
        my $class = legacy_instance(-testing);
        $class->set({ -bad_boy => 1 });
    };
    unless ($@) {
        return "setting parameter failed to catch mis-specified parm";
    }
    return '';
}

########################################
# get                                  #
########################################
sub test_get {
    my $class = legacy_instance(qw(-testing -misc));
    $class->declare('-other');
    my $test_value = '1.0056';
    $class->set({ -testing => $test_value, -misc => 'stuff', '-other' => 'more stuff' });
    eval {
        my $value = $class->get(-testing);
        if ($value ne $test_value) {
            return "value returned was not the same as value set: $@";
        }
        my @list_results = $class->get('-testing','-misc','-other');
        if ($#list_results == 2) {
            unless (($list_results[0] eq $test_value)
                and ($list_results[1] eq 'stuff')
                and ($list_results[2] eq 'more stuff')) {
                return 'returned results are not in correct order';
            }
        } else {
            return 'unexpected number of returned results from get in list context';
        }
        my $item = $class->get('-testing','-other','-misc');
        unless ($item eq 'stuff') {
            return 'failed to return last requested item in a scalar context';
        }
        eval {
            my $value = $class->get;
        };
        unless ($@) {
            return 'failed to catch get with no parameters'
        }
    };
    if ($@) {
        return $@;
    }
    return '';
}

########################################
# exists;                           #
########################################
sub test_exists {
    eval {
        my $test_values = {
            -testing  => 'a',
            -misc     => 'b',
        };
        my @initial_parms = qw(-testing -misc);
        my $class = legacy_instance(@initial_parms);
        $class->set($test_values);
        foreach my $item (@initial_parms) {
            unless ($class->exists($item)) {
                die("exists failed for $item");
            }
        }
        unless (not $class->exists('nosuchparm')) {
            die("exists gave false positive for undeclared parm");
        }
    };

    if ($@) {
        return $@;
    }
    return '';
}

########################################
# all_parms;                           #
########################################
sub test_all_parms {
    eval {
        my $test_values = {
            -testing  => 'a',
            -misc     => 'b',
        };
        my @initial_parms = keys %$test_values;
        my $class = legacy_instance(qw(-testing -misc -extra));
        $class->set($test_values);
        my $parms_hash = $class->all_parms;
        my @initialized_parms = keys %$parms_hash;
        if ($#initialized_parms != $#initial_parms) {
            die ("incorrect number of parms returned by all_parms");
        }
        foreach my $item (@initial_parms) {
            unless (exists $parms_hash->{$item}) {
                die("unexpected key returned by all_parms");
            }
        }
    };

    if ($@) {
        return $@;
    }
    return '';
}

########################################
# list_initialized_parms;              #
########################################
sub test_list_initialized_parms {
    eval {
        my $test_values = {
            -testing => 'a',
        };
        my @initial_parms = keys %$test_values;
        my $class = legacy_instance(qw(-testing -misc));
        $class->set($test_values);
        my @initialized_parms = $class->list_initialized_parms;
        if ($#initialized_parms != $#initial_parms) {
            die ("incorrect number of parms returned by list_initialized_parms");
        }
        my %parms_hash = map { $_ => 1 } @initialized_parms;
        foreach my $item (@initial_parms) {
            unless (exists $parms_hash{$item}) {
                die("unexpected key returned by list_initialized_parms");
            }
        }
    };

    if ($@) {
        return $@;
    }
    return '';
}

########################################
# list_declared_parms;                 #
########################################
sub test_list_declared_parms {
    eval {
        my $test_values = {
            -testing => 'a',
            -misc    => 'b',
        };
        my @initial_parms = keys %$test_values;
        my $class = legacy_instance(@initial_parms);
        my @declared_parms = $class->list_declared_parms;
        if ($#declared_parms != $#initial_parms) {
            die ("incorrect number of parms returned by list_declared_parms");
        }
        my %parms_hash = map { $_ => 1 } @declared_parms;
        foreach my $item (@initial_parms) {
            eval {
                my $value = $class->get($item);
            };
            unless ($@) {
                die("failed to detect use of declared, but not initialized, parm");
            }
        }
    };

    if ($@) {
        return $@;
    }
    return '';
}

########################################
# undeclare                            #
########################################
sub test_undeclare {
    eval {
        my $class = legacy_instance(qw(-testing -misc));
        my $test_value0 = '1.0054';
        my $test_value1 = 'a';
        $class->set({ -testing => $test_value0, -misc => $test_value1 });
        my $value = $class->get(-testing);
        if ($value ne $test_value0) {
            return "value returned was not the same as value set\n";
        }
        $class->undeclare(-testing);
        eval {
            my $new_value = $class->get(-testing);
        };
        unless ($@) {
            die("failed to undeclare key");
        }
        eval {
            $class->undeclare(-testing);
        };
        unless ($@) {
            die("failed to catch 'undeclare' on a never declared key");
        }
    };

    if ($@) {
        return $@;
    }
    return '';
}

########################################
# clear                                #
########################################
sub test_clear {
    eval {
        my $class = legacy_instance(-testing);
        my $test_value = '1.0054';
        $class->set({ -testing => $test_value });
        my $value = $class->get(-testing);
        if ($value ne $test_value) {
            return "value returned was not the same as value set\n";
        }
        $class->clear(-testing);
        my $new_value = $class->get(-testing);
        if (defined $new_value) {
            return "failed to clear value\n";
        }
        eval {
            $class->clear(-other);
        };
        unless ($@) {
            return 'failed to catch clearing of an undeclared parm';
        }
    };
    if ($@) {
        return $@;
    }
    '';
}

#####################################
# legacy tests the old non-inheritance friendly 
# form for proper functionality.
####################################
sub legacy_instance {
    my $instance = Class::NamedParms->new(@_);
    my $legacy_instance = bless $instance->{'Class::NamedParms'}, 'Class::NamedParms';
    return $legacy_instance;
}

##########################################
##########################################

sub run_tests {
    my ($tests) = @_;
    my @commentary = ('');
    my @results = ();
    my $first_test = $do_tests[0];
    my $last_test = $do_tests[$#do_tests];
    my $test_plan = "${first_test}..${last_test}";
    push(@results, $test_plan);
    my $n_failures = 0;
    foreach my $test (@do_tests) {
        my $sub  = $test_subs->{$test}->{-code};
        my $desc = $test_subs->{$test}->{-desc};
        my $failure = '';
        eval { $failure = &$sub; };
        if ($@) {
            $failure = $@;
        }
        if ($failure ne '') {
            chomp $failure;
            push(@results, "not ok $test");
            push(@commentary, "    $desc - $failure");
            $n_failures++;
        } else {
            push(@results, "ok $test");
            push(@commentary, "    $desc - ok");
        }
    }
    push(@results, "END\n");
    print join("\n", @results);
    print STDERR join("\n", @commentary, '');
    return;
}

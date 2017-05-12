#!/usr/bin/perl -w

use strict;
use lib ('./blib','../lib','./lib');
use Class::ParmList ();

my @do_tests=(1..7);

my $test_subs = {
       1 => { -code => \&test_constructors, -desc => 'constructor          ' },
       2 => { -code => \&test1,             -desc => 'legal                ' },
       3 => { -code => \&test2,             -desc => 'required             ' },
       4 => { -code => \&test3,             -desc => 'defaults             ' },
       5 => { -code => \&test4,             -desc => 'stacked parms (hash) ' },
       6 => { -code => \&test5,             -desc => 'stacked parms (list) ' },
       7 => { -code => \&test_bad_parms,    -desc => 'bad parameters       ' },
};
print $do_tests[0],'..',$do_tests[$#do_tests],"\n";
print STDERR "\n";
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
        print "not ok $test\n";
        print STDERR "     $desc                  - $failure\n";
        $n_failures++;
    } else {
        print "ok $test\n";
        print STDERR "     $desc                  - ok\n";

    }
}
print "END\n";
exit;

########################################
# constructors                         #
########################################
sub test_constructors {
    eval {
        my $class = Class::ParmList->new;
    };
    if ($@) {
        return 'direct notation constructor CLASS->new; failed';
    }

    eval {
        my $class = new Class::ParmList;
    };
    if ($@) {
        return 'indirect direct notation constructor new CLASS; failed';
    }

    eval {
        my $class = Class::ParmList::new;
    };
    if ($@) {
        return 'Class function constructor CLASS::new; failed';
    }

    eval {
        my $class = Class::ParmList->new;
        my $nother = $class->new;
    };
    if ($@) {
        return 'Derived instance constructor $instance->new; failed';
    }

    return '';
}

########################################
# bad parms                            #
########################################
sub test_bad_parms {
    eval {
        my $class = Class::ParmList->new({});
    };
    if ($@) {
        return $@;
    }

    my $parms = { -test => 'hello' };

    eval {
        my $class = Class::ParmList->new( -parms => $parms,
                                        -defaults => {},
                                        -required => [],
                                        -nonesuch => [],
                                           -legal => [qw(-test)],
                                         );
		if (defined $class) {
			 die "failed to detect extra parameter";
		}
        my $error = Class::ParmList->error;
        if ($error eq '') {
			 die "no 'error' was available after failed constructor";
        }
    };
    if ($@) {
        return $@;
    }

    eval {
        my $class = Class::ParmList->new( -parms => $parms,
                                        -defaults => {},
                                        -required => [],
                                           -legal => [qw(-test)],
                                         );
		if (not defined $class) {
			 die "failed to create new object and parse data using list";
		}
		eval {
            my ($test) = $class->get();
        };
        unless ($@) {
			 die "failed to catch call to get with no parameters";
        }
		eval {
            my ($test) = $class->get(-what);
        };
        unless ($@) {
			 die "failed to catch call to get illegal parameter";
        }
    };
    if ($@) {
        return $@;
    }
    return '';
}

########################################
# legal                                #
########################################
sub test1 {
    eval {
        my $class = Class::ParmList->new;
    };
    if ($@) {
        return $@;
    }

    my $parms = { -test => 'hello', -test2 => 'hello2', };

    eval {
        my $class = Class::ParmList->new( -parms => {},
                                        -defaults => {},
                                        -required => [],
                                         );
		unless (defined $class) {
			 die "failed to create new object and parse data using empty parameter list";
		}

		if ($class->exists(-test3)) {
			 die "parameter existance test failed for legal but not passed parameter";
        }

        eval {
		    my $example = $class->get(-test3);
        };
        if ($@) {
			    die "get failed for legal but not passed parameter";
        }
    };
    if ($@) {
        return $@;
    }
    eval {
        my $class = Class::ParmList->new( -parms => $parms,
                                        -defaults => {},
                                        -required => [],
                                           -legal => [qw(-test -test2 -test3)],
                                         );
		if (not defined $class) {
			 die "failed to create new object and parse data using list";
		}

		if ($class->exists(-test3)) {
			 die "parameter existance test failed for legal but not passed parameter";
        }

        eval {
		    my $example = $class->get(-test3);
        };
        if ($@) {
			    die "get failed for legal but not passed parameter";
        }

        eval {
		    my $example = $class->get(-test4);
        };
        unless ($@) {
			    die "get failed to catch illegal parameter";
        }

		unless ($class->exists(-test)) {
			 die "parameter existance test failed";
        }

        my @parm_list = $class->list_parms;
        my @wanted_parms = keys %$parms;
        unless ($#parm_list == $#wanted_parms) {
			 die "Unexpected number of parameters returned from list_parms";
        }
        
        my $all_parms = $class->all_parms;
        my @all_parm_keys = keys %$all_parms;
        unless ($#all_parm_keys == $#wanted_parms) {
			 die "Unexpected number of parameters returned from all_parms";
        }
        while (my ($p_key, $p_value) = each %$all_parms) {
            unless ($parms->{$p_key} eq $all_parms->{$p_key}) {
                die "the value for all_parms key $p_key was unexpected";
            }
        }
    };
    if ($@) {
        return $@;
    }

    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {},
                                        -required => [],
                                           -legal => [qw(-test -test2)],
                                         });
		if (not defined $class) {
			 die "failed to create new object and parse data using anon hash";
		}
		my ($test) = $class->get(-test);
    };
    if ($@) {
        return $@;
    }

    eval {
		my $class;
        $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {},
                                        -required => [],
                                           -legal => [-burp],
                                         });
		if (defined $class) {
			 die "failed to flag undeclared parameter";
		}
    };
    if ($@) {
        return $@;
    }
    '';
}
########################################
# required                             #
########################################
sub test2 {
    my $parms = { -test => 'hello' };
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {},
                                        -required => [qw(-burp)],
                                           -legal => [qw(-test)],
                                         });
		if (defined $class) {
			 die "failed to flag missing required parameter";
		}
    };
    if ($@) {
        return $@;
    }
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {},
                                        -required => [qw(-test)],
                                           -legal => [qw(-burp)],
                                         });
		if (not defined $class) {
			 die "failed to accept required parameter";
		}
    };
    if ($@) {
        return $@;
    }
    '';
}
########################################
# defaults                             #
########################################
sub test3 {
    my $parms = { -test => 'hello' };
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {-heathen => 'yes', -test=> 'goodbye' },
                                        -required => [],
                                           -legal => [qw(-test -heathen)],
                                         });
		if (not defined $class) {
			 die "failed to flag missing required parameter";
		}
		my ($test,$heathen) = $class->get(-test,-heathen);
		if ($test ne 'hello') {
			return "failed to overwrite default";
		}
		if ($heathen ne 'yes') {
			return 'failed to set default';
		}
    };
    if ($@) {
        return $@;
    }
    '';
}
########################################
# stacked parms hash                   #
########################################
sub test4 {
    my $parms = [{ '-test' => 'hello' }];
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {-heathen => 'yes', -test=> 'goodbye' },
                                        -required => [],
                                           -legal => [qw(-test -heathen)],
                                         });
		if (not defined $class) {
			 die "failed to flag missing required parameter";
		}
		my ($test,$heathen) = $class->get(-test,-heathen);
		if ($test ne 'hello') {
			return "failed to overwrite default";
		}
		if ($heathen ne 'yes') {
			return 'failed to set default';
		}
    };
    if ($@) {
        return $@;
    }
    '';
}
########################################
# stacked parms list                   #
########################################
sub test5 {
    my $parms = [ '-test' => 'hello' ];
    eval {
        my $class = Class::ParmList->new({ -parms => $parms,
                                        -defaults => {-heathen => 'yes', -test=> 'goodbye' },
                                        -required => [],
                                           -legal => [qw(-test -heathen)],
                                         });
		if (not defined $class) {
			 die "failed to flag missing required parameter";
		}
		my ($test,$heathen) = $class->get(-test,-heathen);
		if ($test ne 'hello') {
			return "failed to overwrite default";
		}
		if ($heathen ne 'yes') {
			return 'failed to set default';
		}
    };
    if ($@) {
        return $@;
    }
    '';
}

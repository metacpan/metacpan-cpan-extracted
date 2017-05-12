#!/usr/bin/env perl

use strict;
use warnings;

BEGIN { print __PACKAGE__ . " - And so it BEGINs … (\${^GLOBAL_PHASE} is '${^GLOBAL_PHASE}')\n" }
use Acme::AllThePerlIsAStage;

my $my_set_at_global = $$;
my $my_set_at_run;
my $my_set_at_begin;
my $my_set_at_unitcheck;
my $my_set_at_check;
my $my_set_at_init;
my $my_set_at_end;
my $my_set_at_init_and_run;

our $our_set_at_global = $$;
our $our_set_at_run;
our $our_set_at_begin;
our $our_set_at_unitcheck;
our $our_set_at_check;
our $our_set_at_init;
our $our_set_at_end;
our $our_set_at_init_and_run;

# Since we are doing BEGIN blocks that call this we need it first:
sub say_stage {
    my ($name) = @_;
    print caller() . " - $name (\${^GLOBAL_PHASE} is '${^GLOBAL_PHASE}')\n";
    return unless $ENV{'AllThePerlIsAStage_verbose'};

    for my $var (
        qw(
        my_set_at_global  my_set_at_run  my_set_at_begin  my_set_at_unitcheck  my_set_at_check  my_set_at_init  my_set_at_end  my_set_at_init_and_run
        our_set_at_global our_set_at_run our_set_at_begin our_set_at_unitcheck our_set_at_check our_set_at_init our_set_at_end our_set_at_init_and_run
        )
      ) {
        no strict 'refs';    ## no critic
        my $val = defined ${$var} ? "'${$var}'" : 'undef() (i.e. not initialized at this point)';
        my $spacing = " " x ( 22 - length($var) );
        print "\t\$$var$spacing is $val\n";
    }

    print "\n";
}

#### now the meat and potatoes ##

say_stage("Global Scope 1");

if ( ${^GLOBAL_PHASE} eq 'RUN' ) {
    $my_set_at_run           = $$;
    $our_set_at_run          = $$;
    $my_set_at_init_and_run  = $$;
    $our_set_at_init_and_run = $$;
    say_stage("IF-RUN 1");
}

BEGIN {
    $my_set_at_begin  = $$;
    $our_set_at_begin = $$;
    say_stage("BEGIN 1");
}

UNITCHECK {
    $my_set_at_unitcheck  = $$;
    $our_set_at_unitcheck = $$;
    say_stage("UNITCHECK 1");
}

CHECK {
    $my_set_at_check  = $$;
    $our_set_at_check = $$;
    say_stage("CHECK 1");
}

INIT {
    $my_set_at_init          = $$;
    $our_set_at_init         = $$;
    $my_set_at_init_and_run  = $$;
    $our_set_at_init_and_run = $$;
    say_stage("INIT 1");
}

END {
    $my_set_at_end  = $$;
    $our_set_at_end = $$;
    say_stage("END 1");
}

END {
    say_stage("END 2");
}

INIT {
    say_stage("INIT 2");
}

CHECK {
    say_stage("CHECK 2");
}

UNITCHECK {
    say_stage("UNITCHECK 2");
}

BEGIN {
    say_stage("BEGIN 2");
}

if ( ${^GLOBAL_PHASE} eq 'RUN' ) {
    say_stage("IF-RUN 2");
}

say_stage("Global Scope 2");

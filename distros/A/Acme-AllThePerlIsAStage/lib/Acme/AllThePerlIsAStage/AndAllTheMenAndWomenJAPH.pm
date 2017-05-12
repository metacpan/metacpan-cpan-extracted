package Acme::AllThePerlIsAStage::AndAllTheMenAndWomenJAPH;

use strict;
use warnings;

BEGIN { print __PACKAGE__ . " - And so it BEGINs … (\${^GLOBAL_PHASE} is '${^GLOBAL_PHASE}')\n" }
$Acme::AllThePerlIsAStage::AndAllTheMenAndWomenJAPH::VERSION = '0.01';

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

sub import {
    _say_stage("inside import()");
}

# Since we are doing BEGIN blocks that call this we need it first:
sub _say_stage {
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

_say_stage("Global Scope 1");

if ( ${^GLOBAL_PHASE} eq 'RUN' ) {
    $my_set_at_run           = $$;
    $our_set_at_run          = $$;
    $my_set_at_init_and_run  = $$;
    $our_set_at_init_and_run = $$;
    _say_stage("IF-RUN 1");
}

BEGIN {
    $my_set_at_begin  = $$;
    $our_set_at_begin = $$;
    _say_stage("BEGIN 1");
}

UNITCHECK {
    $my_set_at_unitcheck  = $$;
    $our_set_at_unitcheck = $$;
    _say_stage("UNITCHECK 1");
}

CHECK {
    $my_set_at_check  = $$;
    $our_set_at_check = $$;
    _say_stage("CHECK 1");
}

INIT {
    $my_set_at_init          = $$;
    $our_set_at_init         = $$;
    $my_set_at_init_and_run  = $$;
    $our_set_at_init_and_run = $$;
    _say_stage("INIT 1");
}

END {
    $my_set_at_end  = $$;
    $our_set_at_end = $$;
    _say_stage("END 1");
}

END {
    _say_stage("END 2");
}

INIT {
    _say_stage("INIT 2");
}

CHECK {
    _say_stage("CHECK 2");
}

UNITCHECK {
    _say_stage("UNITCHECK 2");
}

BEGIN {
    _say_stage("BEGIN 2");
}

if ( ${^GLOBAL_PHASE} eq 'RUN' ) {
    _say_stage("IF-RUN 2");
}

_say_stage("Global Scope 2");

1;

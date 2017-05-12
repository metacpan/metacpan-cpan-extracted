package Acme::AllThePerlIsAStage;

use strict;
use warnings;

$Acme::AllThePerlIsAStage::VERSION = '0.01';
BEGIN { print __PACKAGE__ . " - And so it BEGINs … (\${^GLOBAL_PHASE} is '${^GLOBAL_PHASE}')\n" }

use Acme::AllThePerlIsAStage::AndAllTheMenAndWomenJAPH;

# TODO v0.02: functions
# use Acme::AllThePerlIsAStage::AndAllTheMenAndWomenJAPH 'set_at_begin_via_import';
#
# BEGIN { *set_at_begin_via_block = sub { return $$ }; };
#
# sub set_at_begin_via_sub_defined_at_global;
# *set_at_begin_via_sub_defined_at_global = sub { return $$ };
#
# sub set_at_begin { return $$ }
#
# *set_at_global = sub { return $$ };
# etc …

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

    # TODO v0.02: test that this does not change results
    # TODO v0.02: eval if callable w/and w/out parens?
    # print "\t set_at_begin() is " . (defined &set_at_begin) ? "defined" : "not defined";
    # print "\tset_at_global() is " . (defined &set_at_global) ? "defined" : "not defined";
    # set_at_begin_via_import
    # set_at_begin_via_block
    # set_at_begin_via_sub_defined_at_global
    # set_at_begin_via_sub_defined_at_global
    # set_at_begin
    # set_at_global

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

__END__

=encoding utf-8

=head1 NAME

Acme::AllThePerlIsAStage - Grok perl stages for scripts and modules under use and require–uncompiled and compiled

=head1 VERSION

This document describes Acme::AllThePerlIsAStage version 0.01

=head1 SYNOPSIS

Compare output points to see what-happens-when in order to understand why and decide on what to do:

    perl -e 'use Acme::AllThePerlIsAStage;'
    perl -e 'use Acme::AllThePerlIsAStage;'
    perlcc -e 'use Acme::AllThePerlIsAStage;' -o tmp/use
    ./tmp/use
    ./tmp/use
    perl -e 'use Acme::AllThePerlIsAStage ();'
    perl -e 'use Acme::AllThePerlIsAStage ();'
    perlcc -e 'use Acme::AllThePerlIsAStage;' -o tmp/use_no_import
    ./tmp/use_no_import
    ./tmp/use_no_import
    perl -e 'require Acme::AllThePerlIsAStage;'
    perl -e 'require Acme::AllThePerlIsAStage;'
    perlcc -e 'require Acme::AllThePerlIsAStage;' -o tmp/req
    ./tmp/req
    ./tmp/req

=head1 DESCRIPTION

Sometimes the stages involved in perl’s execution can be hard to grasp. It gets even hairier when you start compiling your code.

When trying to explain and then demonstrate what was happening I found myself writing scripts and modules to output what perl is doing where in order to find out if my understanding lined up with reality. Then to see how reality held up once compiled with perlcc.

Finally, making a set up every few months got old and I thought I’d put it all on CPAN for the masses to enjoy/ignore.

=head1 TL;DR

Too Long; Didn’t Run

TODO v0.02 – fill me out (sorry, ran our of time)

=head2 stage info

TODO v0.02 – fill me out (sorry, ran our of time)

=head2 subroutine info

TODO v0.02 – fill me out (sorry, ran our of time)

=head2 our $vars

TODO v0.02 – fill me out (sorry, ran our of time)

=head2 my $vars

TODO v0.02 – fill me out (sorry, ran our of time)

=head1 INTERFACE

Just use or require the module. It outputs info you can use to visualize and study in order to grok L<perlmod/"BEGIN, UNITCHECK, CHECK, INIT and END">.

If the environment variable 'AllThePerlIsAStage_verbose' is true it outputs info on various symbols at each point in the process.

=head2 use()/require() compiled/uncompiled

    perl -e 'use Acme::AllThePerlIsAStage;'
    perl -e 'use Acme::AllThePerlIsAStage;'
    perlcc -e 'use Acme::AllThePerlIsAStage;' -o tmp/use
    ./tmp/use
    ./tmp/use
    perl -e 'use Acme::AllThePerlIsAStage ();'
    perl -e 'use Acme::AllThePerlIsAStage ();'
    perlcc -e 'use Acme::AllThePerlIsAStage;' -o tmp/use_no_import
    ./tmp/use_no_import
    ./tmp/use_no_import
    perl -e 'require Acme::AllThePerlIsAStage;'
    perl -e 'require Acme::AllThePerlIsAStage;'
    perlcc -e 'require Acme::AllThePerlIsAStage;' -o tmp/req
    ./tmp/req
    ./tmp/req

more verbose:

    AllThePerlIsAStage_verbose=1 perl -e 'use Acme::AllThePerlIsAStage;'
    AllThePerlIsAStage_verbose=1 perl -e 'use Acme::AllThePerlIsAStage;'
    perlcc -e 'use Acme::AllThePerlIsAStage;' -o tmp/use
    AllThePerlIsAStage_verbose=1 ./tmp/use
    AllThePerlIsAStage_verbose=1 ./tmp/use
    AllThePerlIsAStage_verbose=1 perl -e 'use Acme::AllThePerlIsAStage ();'
    AllThePerlIsAStage_verbose=1 perl -e 'use Acme::AllThePerlIsAStage ();'
    perlcc -e 'use Acme::AllThePerlIsAStage;' -o tmp/use_no_import
    AllThePerlIsAStage_verbose=1 ./tmp/use_no_import
    AllThePerlIsAStage_verbose=1 ./tmp/use_no_import
    AllThePerlIsAStage_verbose=1 perl -e 'require Acme::AllThePerlIsAStage;'
    AllThePerlIsAStage_verbose=1 perl -e 'require Acme::AllThePerlIsAStage;'
    perlcc -e 'require Acme::AllThePerlIsAStage;' -o tmp/req
    AllThePerlIsAStage_verbose=1 ./tmp/req
    AllThePerlIsAStage_verbose=1 ./tmp/req

=head2 from a script point of view

There are script's in the module’s share/ dir (not installed on your system but they are there if you want them).

To see what it looks like when use()d from a script, compare:

    ./and_one_man_in_his_time_plays_many_parts.pl
    ./and_one_man_in_his_time_plays_many_parts.pl
    perlcc ./and_one_man_in_his_time_plays_many_parts.pl -o and_one_man_in_his_time_plays_many_parts
    ./and_one_man_in_his_time_plays_many_parts
    ./and_one_man_in_his_time_plays_many_parts

more verbose:

    AllThePerlIsAStage_verbose=1 ./and_one_man_in_his_time_plays_many_parts.pl
    AllThePerlIsAStage_verbose=1 ./and_one_man_in_his_time_plays_many_parts.pl
    AllThePerlIsAStage_verbose=1 perlcc ./and_one_man_in_his_time_plays_many_parts.pl -o and_one_man_in_his_time_plays_many_parts
    AllThePerlIsAStage_verbose=1 ./and_one_man_in_his_time_plays_many_parts
    AllThePerlIsAStage_verbose=1 ./and_one_man_in_his_time_plays_many_parts

To see what it looks like when require()d from a script, compare:

    ./they_have_their_exits_and_their_entrances.pl
    ./they_have_their_exits_and_their_entrances.pl
    perlcc ./they_have_their_exits_and_their_entrances.pl -o they_have_their_exits_and_their_entrances
    ./they_have_their_exits_and_their_entrances
    ./they_have_their_exits_and_their_entrances

more verbose:

    AllThePerlIsAStage_verbose=1 ./they_have_their_exits_and_their_entrances.pl
    AllThePerlIsAStage_verbose=1 ./they_have_their_exits_and_their_entrances.pl
    AllThePerlIsAStage_verbose=1 perlcc ./they_have_their_exits_and_their_entrances.pl -o they_have_their_exits_and_their_entrances
    AllThePerlIsAStage_verbose=1 ./they_have_their_exits_and_their_entrances
    AllThePerlIsAStage_verbose=1 ./they_have_their_exits_and_their_entrances

=head1 DIAGNOSTICS

Throws no warnings or errors of its own.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 This seems useful so why is it in Acme:: instead of Devel::?

I wanted to name it funny and Devel:: is way to serious for that. One of those days I guess :)

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-alltheperlisastage@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

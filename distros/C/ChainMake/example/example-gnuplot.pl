#!/usr/bin/perl

use strict;
use lib '..';
use ChainMake::Functions ':all';

target 'anticrossing.gp', (
    timestamps   => ['$t_name'],
    handler => sub {
        my $t_name=shift;
        open OUT,">",$t_name or print "Can't write $t_name: $!" && return 0;
        print OUT get_gp();
        close OUT;
        1;
    }
);

target 'anticrossing.eps', (
    timestamps   => ['$t_name'],
    requirements => ['$t_base.gp'],
    handler => sub {
        my ($t_name,$t_base,$t_ext)=@_;
        execute_system(
            Linux   => "gnuplot $t_base.gp",
            Windows => "pgnuplot $t_base.gp", # or whatever
        );
    }
);

target ['anticrossing.pdf'], (
    timestamps   => ['$t_name'],
    requirements => ['$t_base.eps'],
    handler => sub {
        my ($t_name,$t_base,$t_ext)=@_;
        execute_system(
            Linux => "epstopdf $t_base.eps",
        );
    }
);

target 'clean', (
    handler => sub {
        unlink qw/anticrossing.gp anticrossing.eps/;
        1;
    }
);

target 'realclean', (
    requirements => ['clean'],
    handler => sub {
        unlink qw/anticrossing.pdf/;
        1;
    }
);

target [qw/all All/], requirements => ['anticrossing.pdf','clean'];

chainmake(@ARGV);


sub get_gp { <<'GNUPLOT'
set encoding iso_8859_1
#
set grid front noxtics noytics
unset key
set border 4095 lw 1
#
set terminal postscript mono enhanced eps 16
set size nosquare 0.6
set output "anticrossing.eps"
#
W12 = 1
E1(delta)=delta
E2(delta)=-delta
Em(delta)=0.5*(E1(delta)+E2(delta))
Ep(delta)=Em(delta)+sqrt(delta**2 + abs(W12)**2)
En(delta)=Em(delta)-sqrt(delta**2 + abs(W12)**2)
set xlabel "{/Symbol D}" 0,0.2
set ylabel "Energie" 1,0
set xtics nomirror ("0" 0)
set ytics nomirror ("e_0" 0) font "Symbol"
#
unset title
unset key
#
set arrow from  1.39717,  2.07915 to 1.67465,  1.97889
set label "{/Symbol e}_+" at 1.36546,  2.12356 right
set arrow from 1.26677, -2.10129 to 1.50424, -1.81656
set label "{/Symbol e}_-" at  1.23130, -2.15538 right
set arrow from 1.35204,  0.833268 to 1.19510,  1.19383
set label "{/Symbol e}_A" at  1.42561,  0.707329 left
set arrow from  1.32098, -0.816016 to  1.18529, -1.176589
set label "{/Symbol e}_B" at  1.45668, -0.816016 left
set arrow from -2,1 to 0,1 nohead lt 3
set arrow from -2,0 to -2,1 heads
set label "t_{AB}" at -1.9,0.5 left
#
plot [-3:3] 0,E1(x) lt 2,E2(x) lt 2,Ep(x) lt 1,En(x) lt 1
GNUPLOT
}

__END__

=head1 example-gnuplot.pl

This is an example script that uses L<ChainMake>. Some documentation would be nice here.
Please see the code for now.

=head1 AUTHOR/COPYRIGHT

This is C<$Id: example-gnuplot.pl 1228 2009-03-15 18:58:06Z schroeer $>.

Copyright 2009 Daniel Schröer (L<schroeer@cpan.org>). Any feedback is appreciated.

This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
=cut  

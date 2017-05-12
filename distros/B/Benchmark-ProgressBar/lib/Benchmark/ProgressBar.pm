# $Id$

package Benchmark::ProgressBar;
use strict;
use warnings;
use Benchmark;
use Term::ProgressBar;
our $VERSION = '0.00001';

sub import {
    Benchmark->export_to_level(1, @_);
}

package # hide from PAUSE
    Benchmark;
use strict;
no warnings 'redefine';

my $default_for = 3;
my $min_for     = 0.1;

our $ProgressTitle;

sub runloop {
    my($n, $c) = @_;

    $n+=0; # force numeric now, so garbage won't creep into the eval
    croak "negative loopcount $n" if $n<0;
    confess usage unless defined $c;
    my($t0, $t1, $td); # before, after, difference

    # find package of caller so we can execute code there
    my($curpack) = caller(0);
    my($i, $pack)= 0;
    while (($pack) = caller(++$i)) {
    last if $pack ne $curpack;
    }

    my $progress = Term::ProgressBar->new({ count => $n, remove => 1, name => $ProgressTitle || "progress" });
    my ($subcode, $subref);
    if (ref $c eq 'CODE') {
    $subcode = "sub { for (1 .. $n) { local \$_; package $pack; 
        \$progress->update(\$_);
        &\$c; } }";
        $subref  = eval $subcode;
    }
    else {
    $subcode = "sub { for (1 .. $n) { local \$_; package $pack;
        \$progress->update(\$_);
 $c;} }";
        $subref  = _doeval($subcode);
    }
    croak "runloop unable to compile '$c': $@\ncode: $subcode\n" if $@;
    print STDERR "runloop $n '$subcode'\n" if $Benchmark::Debug;

    # Give one more line so that the progress bar is easier on the eye
    #print "\n";

    # Wait for the user timer to tick.  This makes the error range more like 
    # -0.01, +0.  If we don't wait, then it's more like -0.01, +0.01.  This
    # may not seem important, but it significantly reduces the chances of
    # getting a too low initial $n in the initial, 'find the minimum' loop
    # in &countit.  This, in turn, can reduce the number of calls to
    # &runloop a lot, and thus reduce additive errors.
    my $tbase = Benchmark->new(0)->[1];
    while ( ( $t0 = Benchmark->new(0) )->[1] == $tbase ) {} ;
    $subref->();
    $t1 = Benchmark->new($n);
    $td = &timediff($t1, $t0);
    timedebug("runloop:",$td);
    $td;
}

sub timethis{
    my($n, $code, $title, $style) = @_;
    my($t, $forn);

    die usage unless defined $code and
                     (!ref $code or ref $code eq 'CODE');

    local $ProgressTitle = $title;
    if ( $n > 0 ) {
	croak "non-integer loopcount $n, stopped" if int($n)<$n;
	$t = timeit($n, $code);
	$title = "timethis $n" unless defined $title;
    } else {
	my $fort  = n_to_for( $n );
	$t     = countit( $fort, $code );
	$title = "timethis for $fort" unless defined $title;
	$forn  = $t->[-1];
    }
    local $| = 1;
    $style = "" unless defined $style;
    printf("%10s: ", $title) unless $style eq 'none';
    print timestr($t, $style, $Benchmark::Default_Format),"\n" unless $style eq 'none';

    $n = $forn if defined $forn;

    # A conservative warning to spot very silly tests.
    # Don't assume that your benchmark is ok simply because
    # you don't get this warning!
    print "            (warning: too few iterations for a reliable count)\n"
	if     $n < $Benchmark::Min_Count
	    || ($t->real < 1 && $n < 1000)
	    || $t->cpu_a < $Benchmark::Min_CPU;
    $t;
}



1;

__END__

=head1 NAME

Benchmark::ProgressBar - Display Progress Bar While You Wait For Your Benchmark

=head1 SYNOPSIS

  use Benchmark::ProgressBar qw(cmpthese);

  cmpthese(10_000, {
    a => sub { ... },
    b => sub { ... },
  } );

=head1 DESCRIPTION

This is a VERY crude combination of Benchmark.pm and Term::ProgressBar.
Basically I got sick of waiting for my benchmarks to finish up without
knowing an ETA.

You can use it as a drop-in replacement for Benchmark.pm, but the only
functions that would display a progress bar are the ones listed here:
cmpthese, timethese, and timeit.

This is achieved via crude (a VERY crude) re-definition of Benchmark.pm's
subrountines, so you shouldn't be mixing it with Benchmark.pm (I don't
know why you would)

It does the job for me, YMMV. Patches are welcome.

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki C<< daisuke@endeworks.jp >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

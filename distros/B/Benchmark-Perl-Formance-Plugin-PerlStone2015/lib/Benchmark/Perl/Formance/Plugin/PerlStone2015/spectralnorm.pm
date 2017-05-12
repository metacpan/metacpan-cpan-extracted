package Benchmark::Perl::Formance::Plugin::PerlStone2015::spectralnorm;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - Eigenvalue using the power method
$Benchmark::Perl::Formance::Plugin::PerlStone2015::spectralnorm::VERSION = '0.002';
# COMMAND LINE:
# /usr/bin/perl spectralnorm.perl-3.perl 5500

# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# Contributed by Andrew Rodland
# Benchmark::Perl::Formance plugin by Steffen Schwigon

use strict;
use warnings;

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use IO::Select;
use Benchmark ':hireswallclock';

our $n;
our $size_of_float;
our $threads;
our @ranges;
our $begin;
our $end;

sub eval_A {
  use integer;
  my $div = ( ($_[0] + $_[1]) * ($_[0] + $_[1] + 1) / 2) + $_[0] + 1;
  no integer;
  1 / $div;
}

sub multiplyAv {
  return map {
    my ($i, $sum) = ($_);
    $sum += eval_A($i, $_) * $_[$_] for 0 .. $#_;
    $sum;
  } $begin .. $end;
}

sub multiplyAtv {
  return map {
    my ($i, $sum) = ($_);
    $sum += eval_A($_, $i) * $_[$_] for 0 .. $#_;
    $sum;
  } $begin .. $end;
}

sub do_parallel {
  my $func = shift;

  my @out;
  my (@fd, @ptr, %fh2proc);
  for my $proc (0 .. $threads - 1) {
    ($begin, $end) = @{ $ranges[$proc] };
    my $pid = open $fd[$proc], "-|";
    if ($pid == 0) {
      print pack "F*", $func->( @_ );
      exit 0;
    } else {
      $fh2proc{ $fd[$proc] } = $proc;
      $ptr[$proc] = $begin;
    }
  }

  my $select = IO::Select->new(@fd);

  while ($select->count) {
    for my $fh ($select->can_read) {
      my $proc = $fh2proc{$fh};
      while (read $fh, my $data, $size_of_float) {
        $out[ $ptr[$proc] ++ ] = unpack "F", $data;
      }
      $select->remove($fh) if eof($fh);
    }
  }

  return @out;
}

sub multiplyAtAv {
  my @array = do_parallel(\&multiplyAv, @_);
  return do_parallel(\&multiplyAtv, @array);
}

sub num_cpus {
  open my $fh, '<', '/proc/cpuinfo' or return; # '
  my $cpus;
  while (<$fh>) {
          $cpus ++ if /^processor[\s]+:/; # 0][]0]; # for emacs cperl-mode indent bug
  }
  return $cpus;
}

sub init {
  ($n) = @_;

  $size_of_float = length pack "F", 0;

  $threads = num_cpus() || 1;

  if ($threads > $n) {
    $threads = $n;
  }

  for my $i (0 .. $threads - 1) {
    use integer;
    $ranges[$i][0] = $n * $i / $threads;
    $ranges[$i][1] = $n * ($i + 1) / $threads - 1;
    no integer;
  }
}

sub run
{
        my ($goal) = @_;

        init($goal);

        my @u = (1) x $n;
        my @v;
        for (0 .. 9) {
                @v = multiplyAtAv( @u );
                @u = multiplyAtAv( @v );
        }

        my ($vBv, $vv);
        for my $i (0 .. $#u) {
                $vBv += $u[$i] * $v[$i];
                $vv += $v[$i] ** 2;
        }

        return sprintf( "%0.9f\n", sqrt( $vBv / $vv ) );
}


sub main
{
        my ($options) = @_;

        my $goal   = $options->{fastmode} ? 250 : 750;
        my $count  = $options->{fastmode} ? 1   : 5;

        my $result;
        my $t = timeit $count, sub { $result = run($goal) };
        return {
                Benchmark     => $t,
                goal          => $goal,
                count         => $count,
                result        => $result,
                n             => $n,
                size_of_float => $size_of_float,
                threads       => $threads,
                ranges        => [ @ranges ],
                begin         => $begin,
                end           => $end,
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::PerlStone2015::spectralnorm - benchmark - Eigenvalue using the power method

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

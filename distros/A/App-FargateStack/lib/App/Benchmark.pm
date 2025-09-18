package App::Benchmark;

use strict;
use warnings;

use List::Util qw(sum);

use Role::Tiny;

use Time::HiRes qw(gettimeofday tv_interval);

use parent qw(Class::Accessor::Fast);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw(benchmark));

########################################################################
sub dump_benchmarks {
########################################################################
  my ($self) = @_;

  my $benchmark = $self->get_benchmark();

  my %benchmarks = %{ $benchmark->{t} };

  my @sorted_benchmarks;

  foreach ( sort { $a cmp $b || $benchmarks{$a} <=> $benchmarks{$b} } keys %benchmarks ) {
    next if $_ eq 'elapsed_time';

    push @sorted_benchmarks, $_, $benchmarks{$_};
  }

  return @sorted_benchmarks;
}

########################################################################
sub benchmark {
########################################################################
  my ( $self, $name ) = @_;

  if ( !$name || !$self->get_benchmark ) {
    my $t0 = [gettimeofday];

    $self->set_benchmark(
      { t0 => $t0,
        t1 => $t0,
        t  => {},
      }
    );

    return;
  }

  my $benchmark = $self->get_benchmark;

  my ( $t, $t0, $t1 ) = @{$benchmark}{qw(t t0 t1)};

  return $t->{$name}
    if exists $t->{$name};

  $t->{elapsed_time} = tv_interval( $t0, [gettimeofday] );
  my $prefix = $name . q{:};

  my @benchmark_parts = map { $t->{$_} } grep {/^$prefix/xsm} keys %{$t};

  $t->{$name} += tv_interval( $t1, [gettimeofday] );

  if (@benchmark_parts) {
    $t->{$name} += sum @benchmark_parts;
  }

  $benchmark->{t1} = [gettimeofday];

  return $t->{$name};
}

1;

use 5.006;    # our
use strict;
use warnings;

package Benchmark::CSV;

our $VERSION = '0.001002';

use Path::Tiny;
use Carp qw( croak carp );
use Time::HiRes qw( gettimeofday tv_interval );
use IO::Handle;
use List::Util qw( shuffle );

# ABSTRACT: Report raw timing results in CSV-style format for advanced processing.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

sub new {
  my ( $self, @rest ) = @_;
  return bless { ref $rest[0] ? %{ $rest[0] } : @rest }, $self;
}

sub output_fh {
  my $nargs = ( my ( $self, $value ) = @_ );
  if ( $nargs >= 2 ) {
    croak 'Cant set output_fh after finalization' if $self->{finalized};
    return ( $self->{output_fh} = $value );
  }
  return $self->{output_fh} if $self->{output_fh};
  if ( not $self->{output} ) {
    return ( $self->{output_fh} = \*STDOUT );
  }
  return ( $self->{output_fh} = Path::Tiny::path( $self->{output} )->openw );
}

sub sample_size {
  my $nargs = ( my ( $self, $value ) = @_ );
  if ( $nargs >= 2 ) {
    croak 'Cant set sample_size after finalization' if $self->{finalized};
    return ( $self->{sample_size} = $value );
  }
  return $self->{sample_size} if defined $self->{sample_size};
  return ( $self->{sample_size} = 1 );
}





sub scale_values {
  my $nargs = ( my ( $self, $value ) = @_ );
  if ( $nargs >= 2 ) {
    croak 'Cant set scale_values after finalization' if $self->{finalized};
    return ( $self->{scale_values} = $value );
  }
  return $self->{scale_values} if exists $self->{scale_values};
  return ( $self->{scale_values} = undef );
}





sub per_second {
  my $nargs = ( my ( $self, $value ) = @_ );
  if ( $nargs >= 2 ) {
    croak 'Cant set per_second after finalization' if $self->{finalized};
    $self->{per_second_values} = $value;
  }
  return $self->{per_second} if exists $self->{per_second};
  return ( $self->{per_second} = undef );
}

sub add_instance {
  my $nargs = ( my ( $self, $name, $method ) = @_ );
  croak 'Too few arguments to ->add_instance( name => sub { })' if $nargs < 3;
  croak 'Cant add instances after execution/finalization' if $self->{finalized};
  $self->{instances} ||= {};
  croak "Cant add instance $name more than once" if exists $self->{instances}->{$name};
  $self->{instances}->{$name} = $method;
  return;
}

# These are hard to use as a default due to linux things.
my $hires_gettime_methods = {
  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars);

  'hires_cputime_process' => {

    # bits/time.h
    # CLOCK_PROCESS_CPUTIME_ID = 2
    start => q[my $start = Time::HiRes::clock_gettime(2)],
    stop  => q[my $stop  = Time::HiRes::clock_gettime(2)],
    diff  => q[ ( $stop - $start )],
  },
  'hires_cputime_thread' => {

    # bits/time.h
    # CLOCK_THREAD_CPUTIME_ID = 3
    start => q[my $start = Time::HiRes::clock_gettime(3)],
    stop  => q[my $stop  = Time::HiRes::clock_gettime(3)],
    diff  => q[ ( $stop - $start )],
  },
};
my $timing_methods = {
  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars);
  'hires_wall' => {
    start => q[my $start = [ gettimeofday ]],
    stop  => q[my $stop = [ gettimeofday ]],
    diff  => q[tv_interval( $start, [ gettimeofday ])],
  },

  # These are all bad because they're very imprecise :(
  'times' => {
    start => q[my (@start) = times],
    stop  => q[my (@stop)  = times],
    diff  => q[ ( $stop[0]+$stop[1] ) - ( $start[0]+$start[1] ) ],
  },
  'times_user' => {
    start => q[my (@start) = times],
    stop  => q[my (@stop)  = times],
    diff  => q[ ( $stop[0] - $start[0] ) ],
  },
  'times_system' => {
    start => q[my (@start) = times],
    stop  => q[my (@stop)  = times],
    diff  => q[ ( $stop[1] - $start[1] ) ],
  },
};
if ( Time::HiRes->can('clock_gettime') ) {
  $timing_methods = { %{$timing_methods}, %{$hires_gettime_methods} };
}





sub timing_method {
  my $nargs = ( my ( $self, $method ) = @_ );
  if ( $nargs >= 2 ) {
    croak 'Cant add instances after execution/finalization' if $self->{finalized};
    if ( not exists $timing_methods->{$method} ) {
      croak "No such timing method $method";
    }
    return ( $self->{timing_method} = $method );
  }
  return $self->{timing_method} if $self->{timing_method};
  return ( $self->{timing_method} = 'hires_wall' );
}

sub _timing_method {
  my ($self) = @_;
  return $timing_methods->{ $self->timing_method };
}

sub _compile_timer {
  ## no critic (Variables::ProhibitUnusedVarsStricter)
  my ( $self, $name, $code, $sample_size ) = @_;
  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars);
  my $run_one = q[ $code->(); ];
  my $run_batch = join qq[\n], map { $run_one } 1 .. $sample_size;
  my ( $starter, $stopper, $diff ) = map { $self->_timing_method->{$_} } qw( start stop diff );
  my $sub;
  if ( $self->per_second and $self->scale_values ) {
    $diff = "( ( $diff > 0 ) ? (( 1 / $diff ) * $sample_size ) : 0 )";
  }
  elsif ( $self->per_second ) {
    $diff = "( ( $diff > 0  ) ? ( 1 / $diff ) : 0 )";
  }
  elsif ( $self->scale_values ) {
    $diff = "( $diff /  $sample_size )";
  }

  my $build_sub = <<"EOF";
  \$sub = sub {
    $starter;
    $run_batch;
    $stopper;
    return ( \$name, sprintf '%f', ( $diff ));
  };
  1
EOF
  local $@ = undef;
  ## no critic (BuiltinFunctions::ProhibitStringyEval, Lax::ProhibitStringyEval::ExceptForRequire)
  if ( not eval $build_sub ) {
    carp $build_sub;
    croak $@;
  }
  return $sub;
}

sub _write_header {
  my ($self) = @_;
  return if $self->{headers_written};
  $self->output_fh->printf( "%s\n", join q[,], sort keys %{ $self->{instances} } );
  $self->{headers_written} = 1;
  $self->{finalized}       = 1;
  return;
}

sub _write_result {
  my ( $self, $result ) = @_;
  $self->output_fh->printf( "%s\n", join q[,], map { $result->{$_} } sort keys %{$result} );
  return;
}

sub run_iterations {
  my $nargs = ( my ( $self, $count ) = @_ );
  croak 'Arguments missing to ->run_iterations( num )' if $nargs < 2;
  $self->_write_header;
  my $sample_size = $self->sample_size;
  my $timers      = {};
  for my $instance ( keys %{ $self->{instances} } ) {
    $timers->{$instance} = $self->_compile_timer( $instance, $self->{instances}->{$instance}, $sample_size );
  }
  my @timer_names = keys %{$timers};
  for ( 1 .. ( $count / $sample_size ) ) {
    $self->_write_result( +{ map { $timers->{$_}->() } shuffle @timer_names } );
  }
  $self->output_fh->flush;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::CSV - Report raw timing results in CSV-style format for advanced processing.

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

  use Benchmark::CSV;

  my $benchmark = Benchmark::CSV->new(
    output => './test.csv',
    sample_size => 10,
  );

  $benchmark->add_instance( 'method_a' => sub {});
  $benchmark->add_instance( 'method_b' => sub {});

  $benchmark->run_iterations(100_000);

=head1 RATIONALE.

I've long found all the other bench-marking utilities well meaning, but easily confusing.

My biggest misgiving is that they give you one, or two values which it has decided is "the time" your code took,
whether its an average, a median, or some other algorithm, ( Such as in C<Benchmark::Dumb> ), they all amount to basically giving
you a data point, which you have to take for granted.

That data point may also change wildly between test runs due to computer load or other factors.

Essentially, the flaw as I see it, is trying to convey what is essentially a I<spectrum> of results as a single point.

C<Benchmark::Dumb> at least gives you variation data, but its rather hard to compare and visualize the results it gives to gain
meaningful insight.

So, I looked to modeling the data differently, and happened to accidentally throw some hand-collected benchmark data into a
Google Spreadsheet Histogram plot, and found it hugely enlightening on what was really going on.

One recurring observation I noticed is code run-time seems to have a very lop-sided distribution

   |   ++
   |   |++
   |   | |
   |   | |
   |   | |
   |   | +++
   |   |   |
   |  ++   ++++++++
   |  +           +++++++++++++++++++++++
 0 +-------------------------------------
  0

Which suggests to me, that unlike many things people usually use statistics for,
where you have a bunch of things evenly on both sides of the mode, code has an I<inherent> minimum run time,
which you might see if your system has all factors in "ideal" conditions, and it has a closely following I<sub-optimal> but
I<common> run time, which I imagine you see because the system can't deliver every cycle of code
in perfect situations every time, even the kernel is selfish and says "Well, if I let your code have exactly 100% CPU for as
long as you wanted it, I doubt even kernel space would be able to do anything till you were quite done"
So observing the minimum time C<AND> the median seem to me, useful for comparing algorithm efficiency.

Observing the maximums is useful too, however, those values trend towards being less useful, as they're likely to be impacted by
CPU randomness slowing things down.

=head1 RATIONALE FOR DUMMIES

Graphs are pretty. I like graphs. Why not benchmark distribution graphs!?

=head1 METHODS

=head2 C<add_instance>

Add a test block.

  ->add_instance( name => sub { } );

B<NOTE:> You can only add test instances prior to executing the tests.

After executing tests, the number of columns and the column headings become C<finalized>.

This is because of how the CSV file is written in parallel with the test batches.

CSV is written headers first, top to bottom, one column at a time.

So adding a new column is impossible after the headers have been written without starting over.

=head2 C<new>

Create a benchmark object.

  my $instance = Benchmark::CSV->new( \%hash );
  my $instance = Benchmark::CSV->new( %hash  );

  %hash = {
    sample_size => # number of times to call each sub in a sample
    output      => # A file path to write to
    output_fh   => # An output filehandle to write to
  };

=head2 C<sample_size>

The number of times to call each sub in a "Sample".

A sample is a block of timed code.

For instance:

  ->sample_size(4);
  ->add_instance( x => $y );
  ->run_iterations(40);

This will create a timer block similar to below.

  my $start = time();
  # Unrolled, because benchmarking indicated unrolling was faster.
  $y->();
  $y->();
  $y->();
  $y->();
  return time() - $start;

That block will then be called 10 times ( 40 total code executions batched into 10 groups of 4 )
and return 10 time values.

=head3 get:C<sample_size>

  my $size = $bench->sample_size;

Value will default to 1 if not passed during construction.

=head3 set:C<sample_size>

  $bench->sample_size(10);

Can be performed at any time prior, but not after running tests.

=head2 C<output_fh>

An output C<filehandle> to write very sloppy C<CSV> data to.

Results will be in Columns, sorted by column name alphabetically.

C<output_fh> defaults to C<*STDOUT>, or opens a file passed to the constructor as C<output> for writing.

=head3 get:C<output_fh>

  my $fh = $bench->output_fh;

Either *STDOUT or an opened C<filehandle>.

=head3 set:C<output_fh>

  $bench->output_fh( \*STDERR );

Can be set at any time prior, but not after, running tests.

=head2 C<run_iterations>

Executes the attached tests C<n> times in batches of L<< C<sample_size>|/sample_size >>.

  ->run_iterations( 10_000_000 );

Because of how it works, simply spooling results at the bottom of the data file, you can call this method
multiple times as necessary and inject more results.

For instance, this could be used to give a progress report.

  *STDOUT->autoflush(1);
  print "[__________]\r[";
  for ( 1 .. 10 ) {
    $bench->run_iterations( 1_000_000 );
    print "#";
  }
  print "]\n";

This is also how you can do timed batches:

  my $start = [gettimeofday];
  # Just execute as much as possible until 10 seconds of wallclock pass.
  while( tv_interval( $start, [ gettimeofday ]) < 10 ) {
    $bench->run_iterations( 1_000 );
  }

=for Pod::Coverage scale_values

=for Pod::Coverage per_second

=for Pod::Coverage timing_method

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

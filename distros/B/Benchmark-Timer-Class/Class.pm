=head1 NAME

Benchmark::Timer::Class - Perl module for timing the execution of methods in a specified object

=head1 SYNOPSIS

  use Benchmark::Timer::Class;
  use The_Real_Module;
  $obj = new The_Real_Module();
  $th  = new Benchmark::Timer::Class($obj);
  $th->method1_name_from_real_module();
  $th->method2_name_from_real_module();
  $th->method1_name_from_real_module();
  $th->report();

=head1 DESCRIPTION

The Benchmark::Timer::Class enables you to determine elapsed 
times for calls to methods of a specified object during normal
running of your program with minimal amount of editing. 

=head2 Methods

=over 10

=cut

package Benchmark::Timer::Class;
use strict;

use Exporter;
use Benchmark::Timer;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw();
$VERSION = '0.02';

use vars qw($AUTOLOAD);

=item $th = Benchmark::Timer::Class->new($original_object);

Takes an object reference and returns a reference to a Benchmark::Timer::Class object

=cut

sub new {
    my ($class,$timed_class) = @_;
    my $self = {};
    $self->{timed_class} = $timed_class;
    return bless $self, $class;
}

=item $th->report;

Outputs a timing report to STDERR

=cut

sub report {
    my $self = shift;
    $self->{stats}->report();
}

=item $th->result($methodname);

Returns the mean time for all calls to method $methodname.

=cut

sub result {
    my $self = shift;
    return $self->{stats}->result(@_);
}

=item $th->results;

Returns the timing data as a hash keyed on object method names.

=cut

sub results {
    my $self = shift;
    return $self->{stats}->results();
}

=item $th->data($methodname), $th->data;

When called with an $methodname returns the raw timing data as an array. 
When called with no arguments returns the raw timing data as hash keyed on 
object method names,  where the values of the hash are lists of timings for 
calls to that object method.

=cut

sub data {
    my $self = shift;
    return $self->{stats}->data(@_);
}

#
# Internal Routine(s)
#
# AUTOLOAD catches all method calls destined for the object being timed
# and wraps them in start() and stop() calls to a Time::Timer object.
#
sub AUTOLOAD {
    my $self = shift;
    # Get the name of the routine that the user wanted to call
    # in the first place.
    my $routine = $AUTOLOAD;
    # Strip off the package/module stuff at the start
    $routine =~ s/.*:://;
    # Dont pass on the DESTROY call
    return if $routine eq 'DESTROY';
    # Create a new Timer object if we dont already have one
    if (!exists $self->{stats}) {
	$self->{stats} = new Benchmark::Timer();
    }
    # Start the timer, call the routine, then stop the timer.
    # Finally return the results to the user.
    my ($result,@results);
    if (wantarray) {
	# User called a routine that required an array/hash return value
	$self->{stats}->start($routine);
	@results = $self->{timed_class}->$routine(@_);
	$self->{stats}->stop($routine);
	return @results;
    } else {
	# User called a routine that required a scalar return value
	$self->{stats}->start($routine);
	$result = $self->{timed_class}->$routine(@_);
	$self->{stats}->stop($routine);
	return $result;
    }
}

=back

=head1 AUTHOR

D. Neil, E<lt>perl@dougneil.co.ukE<gt>

=head1 SEE ALSO

L<Time::HiRes>, L<Benchmark::Timer>

=head1 COPYRIGHT

Copyright(c) 2001 Doug Neil.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__END__

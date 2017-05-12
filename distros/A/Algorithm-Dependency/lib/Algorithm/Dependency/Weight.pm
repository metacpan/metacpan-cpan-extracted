package Algorithm::Dependency::Weight;

=pod

=head1 NAME

Algorithm::Dependency::Weight - Calculate dependency 'weights'

=head1 SYNOPSIS

  # Create a source from a file
  my $Source = Algorithm::Dependency::Source->new( 'file.txt' );
  
  # Create a Weight algorithm object
  my $alg = Algorithm::Dependency::Weight->new( source => $Source );
  
  # Find the weight for a single item
  my $weight = $alg->weight('foo');
  print "The weight of 'foo' is $weight\n";
  
  # Or a group
  my $hash = $alg->weight_hash('foo', 'bar', 'baz');
  print "The weight of 'foo', 'bar', and 'bar' are $hash->{foo},"
      . " $hash->{bar} and $hash->{baz} respectively\n";
  
  # Or all of the items
  my $all = $alg->weight_all;
  print "The following is a list from heaviest to lightest:\n";
  foreach ( sort { $all->{$b} <=> $all->{$a} } keys %$all ) {
      print "$_: $all->{$_}\n";
  }

=head1 DESCRIPTION

In dependency systems, it can often be very useful to calculate
an aggregate or sum for one or all items. For example, to find
the "naive install weight" of a Perl distribution (where "naive"
means you treat each distribution equally), you would want the
distribtion (1) + all its dependencies (n) + all B<their>
dependencies (n2) recursively downwards.

If calculated using a normal L<Algorithm::Dependency> object, the
result would be (in a simple systems) equal to:

  # Create your normal (non-ordered alg:dep)
  my $dependency = Algorithm::Dependency->new( ... );
  
  # Find the naive weight for an item
  my $weight = scalar($dependency->schedule('itemname'));

C<Algorithm::Dependency::Weight> provides a way of doing this
with a little more sophistication, and in a way that should work
reasonable well across all the L<Algorithm::Dependency> family.

Please note that the this might be a little (or more than a little)
slower than it could be for the limited case of generating weights
for all of the items at once in a dependency system with no selected
items and no circular dependencies. BUT you can at least rely on
this class to do the job properly regardless of the particulars of
the situation, which is probably more important.

=head2 METHODS

=cut

use 5.005;
use strict;
use List::Util            ();
use Algorithm::Dependency ();
use Params::Util qw{_INSTANCE _STRING};

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.110';
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new @params

The C<new> constructor creates a new C<Algorithm::Dependency::Weight>
object. It takes a number of key/value pairs as parameters (although
at the present time only one).

=over 4

=item source => $Source

The C<source> param is mostly the same as for L<Algorithm::Dependency>.
The one addition is that as a source you can provide an
L<Algorithm::Dependency> object, and the L<Algorithm::Dependency::Source>
for that will be used.

=back

Returns a new C<Algorithm::Dependency::Weight> object, or C<undef> on error.

=cut

sub new {
	my $class = shift;
	my %args  = @_;

	# Get the source object, or derive it from an existing alg-dep
	my $source = _INSTANCE($args{source}, 'Algorithm::Dependency')
		? $args{source}->source
		: _INSTANCE($args{source}, 'Algorithm::Dependency::Source')
		or return undef;

	# Build the alg-dep object we use
	my $algdep = Algorithm::Dependency->new(
		source         => $source,
		ignore_orphans => 1,
		) or return undef;

	# Create the basic object
	my $self = bless {
		source => $source,
		algdep => $algdep,
		weight => {},
		}, $class;

	$self;
}

=pod

=head2 source

The C<source> accessor returns the source used for the weight calculations.

This will be either the one passed to the constructor, or the source from
inside the C<Algorithm::Dependency> object passed as the C<source> param
(B<not> the object itself, B<its> source).

=cut

sub source {
	$_[0]->{source}
}





#####################################################################
# Algorithm::Dependency::Weight Methods

=pod

=head2 weight $name

The C<weight> method takes the name of a single item and calculates its
weight based on the configuration of the C<Algorithm::Dependency::Weight>
object.

Returns the weight as a scalar (which in the naive case will be an
integer, but in more complex uses may be any real number), or C<undef>
on error.

=cut

sub weight {
	my $self = shift;
	my $id   = defined(_STRING($_[0])) ? shift : return undef;
	$self->{weight}->{$id} or
	$self->{weight}->{$id} = $self->_weight($id);
}

sub _weight {
	my $self  = shift;
	my $items = $self->{algdep}->schedule($_[0]) or return undef;
	scalar(@$items);
}

=pod

=head2 weight_merged @names

The C<weight_merged> method takes the name of a set of items and
calculates an aggregated weight for the whole set.

Returns the weight as a scalar, or C<undef> on error.

=cut

sub weight_merged {
	my $self  = shift;
	my $items = $self->{algdep}->schedule(@_) or return undef;
	scalar(@$items);
}

=pod

=head2 weight_hash @names

The C<weight_hash> method takes a list of item names, and calculates
their weights.

Returns a reference to a C<HASH> with the item names as keys and weights
as values, or C<undef> on error.

=cut

sub weight_hash {
	my $self  = shift;
	my @names = @_;

	# Iterate over the list
	my %hash = ();
	foreach my $name ( @names ) {
		if ( $self->{weight}->{$name} ) {
			$hash{$name} = $self->{weight}->{$name};
			next;
		}
		$hash{$name} = $self->weight($name) or return undef;
	}

	\%hash;
}

=pod

=head2 weight_all

The C<weight_all> method provides the one-shot method for getting the
weights of all items at once. Please note that this does not do
anything different or special, but is slightly faster than iterating
yourself.

Returns a reference to a C<HASH> with the item names as keys and weights
as values, or C<undef> on error.

=cut

sub weight_all {
	my $self  = shift;
	my @items = $self->source->items;
	defined $items[0] or return undef;
	$self->weight_hash( map { $_->id } @items );
}

1;

=pod

=head1 TO DO

- Add support for non-naive weights via either custom code or method name

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Algorithm-Dependency>

For general comments, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Algorithm::Dependency>, L<Algorithm::Dependency::Source>

=head1 COPYRIGHT

Copyright 2003 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
